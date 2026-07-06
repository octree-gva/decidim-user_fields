# frozen_string_literal: true

require "spec_helper"

describe Decidim::CustomUserFields::Verifications::Builder do
  subject(:builder) { described_class.new("TestFlow") }

  describe "#register_workflow!" do
    it "registers a decidim verification workflow" do
      workflow = Class.new do
        attr_accessor :form, :metadata_cell, :ephemerable, :renewable, :time_between_renewals
      end.new

      allow(Decidim::Verifications).to receive(:register_workflow).and_yield(workflow)
      builder.add_field(:foo, type: :text)

      builder.register_workflow!

      expect(Decidim::Verifications).to have_received(:register_workflow).with(:test_flow)
      expect(workflow.form).to eq("Decidim::CustomUserFields::Verifications::TestFlow")
    end
  end

  describe "extra_field_ref requirements" do
    it "requires a customization when extra_field_ref is used" do
      with_customizations do
        register_test_customization(:community) do |customization|
          customization.registration_fields { |set| set.add_field(:foo, type: :dummy) }
        end

        builder = described_class.new("BadFlow")
        builder.add_field(:foo, type: :extra_field_ref, ref: :foo)

        expect do
          builder.register_workflow!
        end.to raise_error(Decidim::CustomUserFields::Error, /must be registered inside a customization/)
      end
    end

    it "registers workflow when extra_field_ref matches customization fields" do
      with_customizations do
        register_test_customization(:community) do |customization|
          customization.registration_fields { |set| set.add_field(:foo, type: :dummy) }
        end

        builder = described_class.new("GoodFlow", customization: :community)
        builder.add_field(:foo, type: :extra_field_ref, ref: :foo)

        allow(Decidim::Verifications).to receive(:register_workflow)
        expect { builder.register_workflow! }.not_to raise_error
      end
    end
  end
end
