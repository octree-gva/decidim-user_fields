# frozen_string_literal: true

require "spec_helper"

describe Decidim::CustomUserFields::FieldDefinition do
  let(:handler_name) { "extended_data" }

  it "builds a dummy field" do
    field = described_class.new(:test, { type: :dummy }, handler_name)
    expect(field.type).to eq(:dummy)
    expect(field.field).to be_a(Decidim::CustomUserFields::Fields::DummyField)
  end

  it "builds a text field" do
    field = described_class.new(:test, { type: :text }, handler_name)
    expect(field.field).to be_a(Decidim::CustomUserFields::Fields::TextField)
  end

  it "builds a textarea field" do
    field = described_class.new(:test, { type: :textarea }, handler_name)
    expect(field.field).to be_a(Decidim::CustomUserFields::Fields::TextAreaField)
  end

  it "builds a date field" do
    field = described_class.new(:test, { type: :date }, handler_name)
    expect(field.field).to be_a(Decidim::CustomUserFields::Fields::DateField)
  end

  it "builds an extra_field_ref field" do
    field = described_class.new(:test, { type: :extra_field_ref }, handler_name)
    expect(field.field).to be_a(Decidim::CustomUserFields::Fields::ExtraFieldRefField)
  end

  it "raises for unsupported types" do
    expect do
      described_class.new(:test, { type: :nope }, handler_name)
    end.to raise_error(Decidim::CustomUserFields::Error, /not supported/)
  end
end
