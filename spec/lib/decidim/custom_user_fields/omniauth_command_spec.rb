# frozen_string_literal: true

require "spec_helper"

describe Decidim::CustomUserFields::OmniauthCommand do
  let(:command_class) do
    Class.new do
      prepend Decidim::CustomUserFields::OmniauthCommand

      attr_reader :form

      def initialize(form)
        @form = form
      end
    end
  end

  describe "#persist_omniauth_extended_data!" do
    it "persists validated extended_data after omniauth user creation" do
      with_customizations do
        organization = create(:organization)
        user = create(:user, organization:, extended_data: {})
        register_test_customization(:default) do |customization|
          customization.registration_fields do |set|
            set.add_field(:role, type: :text, values_in: %w(member admin))
          end
        end
        enable_customization_for(organization, :default)

        form = instance_double("Form", current_organization: organization)
        allow(form).to receive(:[]).with(:default_role).and_return("member")

        cmd = command_class.new(form)
        cmd.instance_variable_set(:@user, user)
        cmd.send(:persist_omniauth_extended_data!)

        expect(user.reload.extended_data["default_role"]).to eq("member")
      end
    end

    it "raises when extended_data validation fails" do
      with_customizations do
        organization = create(:organization)
        user = create(:user, organization:, extended_data: {})
        register_test_customization(:default) do |customization|
          customization.registration_fields do |set|
            set.add_field(:role, type: :text, values_in: %w(member admin))
          end
        end
        enable_customization_for(organization, :default)

        form = instance_double("Form", current_organization: organization)
        allow(form).to receive(:[]).with(:default_role).and_return("guest")

        cmd = command_class.new(form)
        cmd.instance_variable_set(:@user, user)

        expect { cmd.send(:persist_omniauth_extended_data!) }.to raise_error(ActiveRecord::RecordInvalid)
        expect(user.reload.extended_data).to eq({})
      end
    end
  end
end
