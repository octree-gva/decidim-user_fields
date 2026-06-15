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

  describe "#field_set" do
    it "stores the field set name" do
      builder.field_set(:community)
      expect(builder.field_set).to eq(:community)
    end
  end

  describe "#register_workflow!" do
    it "requires field_set when extra_field_ref is used" do
      with_registration_field_sets do
        Decidim::CustomUserFields.register_field_set(:community) { |set| set.add_field(:foo, type: :dummy) }
        builder.add_field(:foo, type: :extra_field_ref)

        expect do
          builder.register_workflow!
        end.to raise_error(Decidim::CustomUserFields::Error, /field_set must be set/)
      end
    end

    it "registers workflow when extra_field_ref matches field_set" do
      with_registration_field_sets do
        Decidim::CustomUserFields.register_field_set(:community) { |set| set.add_field(:foo, type: :dummy) }
        builder.field_set(:community)
        builder.add_field(:foo, type: :extra_field_ref)

        workflow = Class.new do
          attr_accessor :form, :metadata_cell, :ephemerable, :renewable, :time_between_renewals
        end.new
        allow(Decidim::Verifications).to receive(:register_workflow).and_yield(workflow)

        expect { builder.register_workflow! }.not_to raise_error
        expect(workflow.form).to eq("Decidim::CustomUserFields::Verifications::TestVerification")
      end
    end
  end
end
