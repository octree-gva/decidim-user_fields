# frozen_string_literal: true

require "spec_helper"

describe Decidim::CustomUserFields::Fields::TextField do
  let(:definition) { Decidim::CustomUserFields::FieldDefinition.new(:test_field, { type: :text }.merge(options), "extended_data") }
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

      it "requires presence" do
        allow(field).to receive(:label).and_return("msg")

        field.configure_form(form_class)

        expect(form_class.validations.fetch(:test_field)).to include(presence: true)
      end
    end

    context "when values_in is set" do
      let(:options) { { values_in: %w(a b) } }

      it "adds an inclusion validation" do
        allow(field).to receive(:label).and_return("msg")

        field.configure_form(form_class)

        inclusion = form_class.validations.fetch(:test_field).fetch(:inclusion)
        expect(inclusion[:in]).to eq(%w(a b))
        expect(inclusion[:message]).to respond_to(:call)
      end
    end

    context "when format is set" do
      let(:options) { { format: /\A\d+\z/ } }

      it "adds a format validation" do
        allow(field).to receive(:label).and_return("msg")

        field.configure_form(form_class)

        format = form_class.validations.fetch(:test_field).fetch(:format)
        expect(format[:with]).to eq(/\A\d+\z/)
        expect(format[:message]).to respond_to(:call)
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

  describe "#map_model" do
    it "strips the value when present" do
      form = {}
      data = { test_field: "  hi " }

      field.map_model(form, data)

      expect(form[:test_field]).to eq("hi")
    end
  end
end
