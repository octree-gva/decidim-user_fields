# frozen_string_literal: true

require "spec_helper"

describe Decidim::CustomUserFields::Command do
  let(:command_class) do
    Class.new do
      prepend Decidim::CustomUserFields::Command

      attr_reader :form, :current_user

      def initialize(form, current_user: nil)
        @form = form
        @current_user = current_user
      end
    end
  end

  describe "#extended_data" do
    it "merges only active customization values into user extended_data" do
      with_customizations do
        organization = create(:organization)
        register_test_customization(:default) do |customization|
          customization.registration_fields { |set| set.add_field(:foo, type: :dummy) }
        end
        register_test_customization(:other) do |customization|
          customization.registration_fields { |set| set.add_field(:bar, type: :dummy) }
        end
        enable_customization_for(organization, :default)

        form = instance_double("Form", current_organization: organization)
        allow(form).to receive(:[]).with(:default_foo).and_return("bar")

        cmd = command_class.new(form)
        cmd.instance_variable_set(:@user, create(:user, organization:, extended_data: { existing: 1 }))

        data = cmd.send(:extended_data)

        expect(data).to include("existing" => 1, default_foo: "bar")
        expect(data).not_to have_key(:other_bar)
      end
    end
  end

  describe "#update_personal_data" do
    it "updates profile fields and merges extended_data from active customizations" do
      with_customizations do
        organization = create(:organization)
        user = create(:user, organization:, extended_data: { existing: "keep" })
        register_test_customization(:default) do |customization|
          customization.registration_fields { |set| set.add_field(:foo, type: :dummy) }
        end
        enable_customization_for(organization, :default)

        form = instance_double(
          "Form",
          current_organization: organization,
          locale: "en",
          name: "New Name",
          nickname: "newnick",
          email: "new@example.org",
          personal_url: "https://example.org",
          about: "About me"
        )
        allow(form).to receive(:[]).with(:default_foo).and_return("bar")

        cmd = command_class.new(form, current_user: user)
        cmd.instance_variable_set(:@form, form)

        cmd.send(:update_personal_data)

        expect(user.name).to eq("New Name")
        expect(user.extended_data).to include("existing" => "keep", "default_foo" => "bar")
      end
    end
  end

  describe "#create_user" do
    it "calls Decidim::User.create! with extended_data in the payload" do
      with_customizations do
        organization = create(:organization)
        register_test_customization(:default) do |customization|
          customization.registration_fields { |set| set.add_field(:foo, type: :dummy) }
        end
        enable_customization_for(organization, :default)

        form = instance_double(
          "Form",
          email: "user@example.org",
          name: "User",
          nickname: "user",
          password: "S4CGQ9AM4ttJdPKS",
          current_organization: organization,
          tos_agreement: true,
          newsletter_at: nil,
          current_locale: "en"
        )
        allow(form).to receive(:[]).with(:default_foo).and_return("bar")

        cmd = command_class.new(form)

        expect(Decidim::User).to receive(:create!).with(hash_including(extended_data: include(default_foo: "bar"))).and_call_original

        cmd.send(:create_user)
      end
    end
  end
end
