# frozen_string_literal: true

require "spec_helper"

describe Decidim::CustomUserFields::Fields::DummyField do
  let(:definition) { Decidim::CustomUserFields::FieldDefinition.new(:test_field, { type: :dummy }.merge(options), "extended_data") }
  let(:field) { definition.field }
  let(:options) { {} }

  let(:form_class) do
    Class.new do
      class << self
        attr_reader :attributes, :validations

        def attribute(name, type)
          (@attributes ||= {})[name] = type
        end

        def validates(name, validations, **)
          (@validations ||= {})[name] = validations
        end
      end
    end
  end

  describe "#validation_hash" do
    it "defaults to empty" do
      expect(field.validation_hash).to eq({})
    end
  end

  describe "#configure_form" do
    it "defines the attribute and uses the validation hash" do
      allow(field).to receive(:validation_hash).and_return(presence: true)

      field.configure_form(form_class)

      expect(form_class.attributes).to include(test_field: String)
      expect(form_class.validations.fetch(:test_field)).to eq(presence: true)
    end
  end

  describe "#sanitized_value" do
    it "strips and turns blank into nil" do
      expect(field.sanitized_value("  hello ")).to eq("hello")
      expect(field.sanitized_value("   ")).to be_nil
      expect(field.sanitized_value(nil)).to be_nil
    end
  end

  describe "#form_tag" do
    it "returns a json payload" do
      allow(field).to receive(:label_exists?).and_return(false)
      allow(field).to receive(:label).and_return("label")

      payload = JSON.parse(field.form_tag(nil))
      expect(payload).to include("name" => "test_field")
      expect(payload).to include("label" => "label")
      expect(payload).to include("class_name" => field.class_name)
    end
  end
end
