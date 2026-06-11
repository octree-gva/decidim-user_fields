# frozen_string_literal: true

require "spec_helper"

describe Decidim::CustomUserFields::Fields::GenericField do
  let(:definition) { Decidim::CustomUserFields::FieldDefinition.new(:my_field, { type: :dummy }, "extended_data") }
  let(:options) { {} }
  let(:field) { described_class.new(definition, options) }

  describe "#required?" do
    it "is false by default" do
      expect(field.required?).to be(false)
    end

    context "when required is true" do
      let(:options) { { required: true } }

      it "is true" do
        expect(field.required?).to be(true)
      end
    end
  end

  describe "#skip_hashing?" do
    it "is false by default" do
      expect(field.skip_hashing?).to be(false)
    end

    context "when skip_hashing is set" do
      let(:options) { { skip_hashing: true } }

      it "is true" do
        expect(field.skip_hashing?).to be(true)
      end
    end
  end

  describe "#class_name" do
    it "is stable and includes type and name" do
      expect(field.class_name).to eq("field field--dummy field--my_field")
    end
  end

  describe "#label_class_name" do
    it "is stable and includes type and name" do
      expect(field.label_class_name).to eq("field_label field_label--dummy field_label--my_field")
    end
  end

  describe "#label" do
    it "returns the i18n identifier and logs when missing" do
      i18n_id = "decidim.custom_user_fields.extended_data.my_field.label"

      allow(I18n).to receive(:exists?).with(i18n_id).and_return(false)
      expect(Rails.logger).to receive(:error).with("Missing #{i18n_id}")

      expect(field.label(:label)).to eq(i18n_id)
    end

    it "returns the translation when present" do
      i18n_id = "decidim.custom_user_fields.extended_data.my_field.label"

      allow(I18n).to receive(:exists?).with(i18n_id).and_return(true)
      allow(I18n).to receive(:t).with(i18n_id, default: i18n_id).and_return("Translated")

      expect(field.label(:label)).to eq("Translated")
    end
  end
end
