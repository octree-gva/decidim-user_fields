# frozen_string_literal: true

require "spec_helper"

describe Decidim::CustomUserFields::Fields::TextAreaField do
  let(:definition) { Decidim::CustomUserFields::FieldDefinition.new(:test_field, { type: :textarea }.merge(options), "extended_data") }
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

  describe "#configure_form" do
    it "defines the attribute and validations" do
      allow(field).to receive(:label).and_return("msg")

      field.configure_form(form_class)

      expect(form_class.attributes).to include(test_field: String)
      expect(form_class.validations).to be_nil
    end

    context "when required" do
      let(:options) { { required: true } }

      it "requires presence with a message" do
        allow(field).to receive(:label).and_return("required-msg")

        field.configure_form(form_class)

        presence = form_class.validations.fetch(:test_field).fetch(:presence)
        expect(presence).to include(message: "required-msg")
      end
    end

    context "when min/max are configured" do
      let(:options) { { min: 2, max: 5 } }

      it "adds a length validation" do
        allow(field).to receive(:label).and_return("msg")

        field.configure_form(form_class)

        length = form_class.validations.fetch(:test_field).fetch(:length)
        expect(length).to include(minimum: 2, maximum: 5)
        expect(form_class.validations.fetch(:test_field)).to include(allow_blank: true)
      end
    end
  end

  describe "#sanitized_value" do
    it "strips and turns blank into nil" do
      expect(field.sanitized_value("  hello ")).to eq("hello")
      expect(field.sanitized_value("   ")).to be_nil
      expect(field.sanitized_value(nil)).to be_nil
    end
  end
end
