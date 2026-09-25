# frozen_string_literal: true

require "spec_helper"

describe Decidim::CustomUserFields::Fields::DateField do
  let(:definition) { Decidim::CustomUserFields::FieldDefinition.new(:birthdate, { type: :date }.merge(options), "extended_data") }
  let(:field) { definition.field }
  let(:options) { {} }

  let(:form_class) do
    Class.new do
      class << self
        attr_reader :attributes, :validations

        def attribute(name, type)
          (@attributes ||= {})[name] = type
        end

        def validates(name, **validations)
          (@validations ||= {})[name] = validations
        end
      end
    end
  end

  describe "#configure_form" do
    it "defines the attribute and a strict format validation" do
      allow(field).to receive(:label).and_return("msg")

      field.configure_form(form_class)

      expect(form_class.attributes).to include(birthdate: String)
      expect(form_class.validations.fetch(:birthdate).dig(:format, :with)).to eq(/\A\d{4}-\d{2}-\d{2}\z/)
    end
  end

  describe "#validate" do
    let(:model_class) do
      Class.new do
        include ActiveModel::Model
        attr_accessor :birthdate
      end
    end

    it "adds a validation error when the date is invalid" do
      errors = model_class.new.errors

      allow(field).to receive(:label).with(:bad_date).and_return("bad_date")

      field.validate("not-a-date", {}, errors)

      expect(errors[:birthdate]).to include("bad_date")
    end

    context "with boundaries" do
      let(:options) { { not_before: "2000-01-01", not_after: "2000-12-31" } }

      it "adds errors when out of range" do
        errors = model_class.new.errors

        allow(field).to receive(:label).with(:bad_not_before).and_return("bad_not_before")
        allow(field).to receive(:label).with(:bad_not_after).and_return("bad_not_after")

        field.validate("1999-12-31", {}, errors)
        field.validate("2001-01-01", {}, errors)

        expect(errors[:birthdate]).to include("bad_not_before", "bad_not_after")
      end
    end
  end
end
