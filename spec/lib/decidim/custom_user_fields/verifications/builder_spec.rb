# frozen_string_literal: true

require "spec_helper"

describe Decidim::CustomUserFields::Verifications::Builder do
  let(:name) { "test_verification" }
  let(:builder) { described_class.new(name) }

  describe "#handler_name" do
    it "underscores the class name" do
      expect(builder.klass_name).to eq("TestVerification")
      expect(builder.handler_name).to eq("test_verification")
    end
  end

  describe "#renewable!" do
    it "marks as renewable and stores time_between_renewals" do
      builder.renewable!(3.days)
      expect(builder.renewable?).to be(true)
      expect(builder.time_between_renewals).to eq(3.days)
    end
  end

  describe "#ephemerable!" do
    it "marks as ephemerable" do
      builder.ephemerable!
      expect(builder.ephemerable?).to be(true)
    end
  end

  describe "#add_field" do
    it "adds a field definition with handler name" do
      expect do
        builder.add_field(:foo, type: :dummy)
      end.to change(builder.fields, :length).by(1)

      field_def = builder.fields.first
      expect(field_def).to be_a(Decidim::CustomUserFields::FieldDefinition)
      expect(field_def.name).to eq(:foo)
      expect(field_def.handler_name).to eq(builder.handler_name)
    end
  end
end
