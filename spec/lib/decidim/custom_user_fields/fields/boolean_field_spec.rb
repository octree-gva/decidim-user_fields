# frozen_string_literal: true

require "spec_helper"

describe Decidim::CustomUserFields::Fields::BooleanField do
  let(:definition) { Decidim::CustomUserFields::FieldDefinition.new(:flag, { type: :boolean, required: true }, "extended_data") }
  let(:field) { definition.field }

  describe "#sanitized_value" do
    it "casts truthy values to true" do
      expect(field.sanitized_value("1")).to be(true)
      expect(field.sanitized_value(true)).to be(true)
    end

    it "casts falsy values to false" do
      expect(field.sanitized_value("0")).to be(false)
      expect(field.sanitized_value(false)).to be(false)
    end
  end
end
