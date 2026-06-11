# frozen_string_literal: true

require "spec_helper"

describe Decidim::CustomUserFields::Verifications do
  around do |example|
    original_classes = described_class.verification_classes.dup
    described_class.verification_classes.clear
    example.run
  ensure
    described_class.verification_classes.replace(original_classes)
  end

  describe ".create_verification_class" do
    it "creates a handler class under the namespace and tracks it" do
      klass_name = "TestVerification#{SecureRandom.hex(4)}"

      klass = described_class.create_verification_class(klass_name)

      expect(klass.name).to eq("Decidim::CustomUserFields::Verifications::#{klass_name}")
      expect(described_class.verification_classes).to include(klass)
    ensure
      described_class.send(:remove_const, klass_name) if described_class.const_defined?(klass_name)
    end
  end

  describe ".register" do
    it "registers a decidim workflow with a custom handler form" do
      workflow = Class.new do
        attr_accessor :form, :metadata_cell, :ephemerable, :renewable, :time_between_renewals
      end.new

      allow(Decidim::Verifications).to receive(:register_workflow).and_yield(workflow)

      handler_name = "my_verification#{SecureRandom.hex(4)}"
      klass_name = handler_name.camelize

      described_class.register(handler_name) do |builder|
        builder.ephemerable!
        builder.renewable!(2.days)
        builder.add_field(:test_field, type: :text)
      end

      expect(Decidim::Verifications).to have_received(:register_workflow).with(handler_name.to_sym)
      expect(workflow.form).to eq("Decidim::CustomUserFields::Verifications::#{klass_name}")
      expect(workflow.metadata_cell).to eq("decidim/verifications/authorization_metadata")
      expect(workflow.ephemerable).to be(true)
      expect(workflow.renewable).to be(true)
      expect(workflow.time_between_renewals).to eq(2.days)
    ensure
      described_class.send(:remove_const, klass_name) if described_class.const_defined?(klass_name)
    end
  end
end
