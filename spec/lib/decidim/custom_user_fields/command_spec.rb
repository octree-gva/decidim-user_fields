# frozen_string_literal: true

require "spec_helper"

describe Decidim::CustomUserFields::Command do
  let(:command_class) do
    Class.new do
      prepend Decidim::CustomUserFields::Command

      attr_reader :form

      def initialize(form)
        @form = form
      end
    end
  end

  describe "#extended_data" do
    it "merges only active field set values into user extended_data" do
      with_registration_field_sets do
        organization = create(:organization)
        register_test_field_set(:default) { |set| set.add_field(:foo, type: :dummy) }
        register_test_field_set(:other) { |set| set.add_field(:bar, type: :dummy) }
        activate_field_set_for(organization, :default)

        form = instance_double("Form", current_organization: organization, foo: "bar", bar: "ignored")
        allow(form).to receive(:[]).with(:foo).and_return("bar")

        cmd = command_class.new(form)
        cmd.instance_variable_set(:@user, create(:user, organization:, extended_data: { existing: 1 }))

        data = cmd.send(:extended_data)

        expect(data).to include("existing" => 1, foo: "bar")
        expect(data).not_to have_key(:bar)
      end
    end
  end

  describe "#create_user" do
    it "calls Decidim::User.create! with extended_data in the payload" do
      with_registration_field_sets do
        organization = create(:organization)
        register_test_field_set(:default) { |set| set.add_field(:foo, type: :dummy) }
        activate_field_set_for(organization, :default)

        form = instance_double(
          "Form",
          email: "user@example.org",
          name: "User",
          nickname: "user",
          password: "S4CGQ9AM4ttJdPKS",
          current_organization: organization,
          tos_agreement: true,
          newsletter_at: nil,
          current_locale: "en",
          foo: nil
        )
        allow(form).to receive(:[]).with(:foo).and_return("bar")

        cmd = command_class.new(form)

        expect(Decidim::User).to receive(:create!).with(hash_including(extended_data: include(foo: "bar"))).and_call_original

        cmd.send(:create_user)
      end
    end
  end
end
