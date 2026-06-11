# frozen_string_literal: true

require "spec_helper"

describe Decidim::CustomUserFields do
  around do |example|
    original = described_class.custom_fields.dup
    described_class.custom_fields.clear
    example.run
  ensure
    described_class.custom_fields.replace(original)
  end

  describe ".default_email_on_notification" do
    it "defaults to false" do
      expect(described_class.default_email_on_notification).to be(false)
    end
  end

  describe ".add_field" do
    it "adds a field definition and returns self" do
      expect do
        expect(described_class.add_field(:foo, type: :dummy)).to eq(described_class)
      end.to change(described_class.custom_fields, :length).by(1)

      field = described_class.custom_fields.last
      expect(field).to be_a(Decidim::CustomUserFields::FieldDefinition)
      expect(field.name).to eq(:foo)
      expect(field.type).to eq(:dummy)
      expect(field.handler_name).to eq("extended_data")
    end
  end
end
