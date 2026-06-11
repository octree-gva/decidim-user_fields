# frozen_string_literal: true

require "spec_helper"

describe Decidim::CustomUserFields::Command do
  around do |example|
    original = Decidim::CustomUserFields.custom_fields.dup
    Decidim::CustomUserFields.custom_fields.clear
    example.run
  ensure
    Decidim::CustomUserFields.custom_fields.replace(original)
  end

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
    it "merges current form fields into user extended_data" do
      Decidim::CustomUserFields.custom_fields << Decidim::CustomUserFields::FieldDefinition.new(:foo, { type: :dummy }, "extended_data")

      form = { foo: "bar" }
      cmd = command_class.new(form)
      cmd.instance_variable_set(:@user, create(:user, extended_data: { existing: 1 }))

      data = cmd.send(:extended_data)

      expect(data).to include("existing" => 1, :foo => "bar")
    end
  end

  describe "#create_user" do
    it "calls Decidim::User.create! with extended_data in the payload" do
      Decidim::CustomUserFields.custom_fields << Decidim::CustomUserFields::FieldDefinition.new(:foo, { type: :dummy }, "extended_data")

      organization = create(:organization)

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
