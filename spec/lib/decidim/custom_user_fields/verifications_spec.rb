# frozen_string_literal: true

require "spec_helper"

describe Decidim::CustomUserFields::Verifications do
  around do |example|
    original_classes = described_class.verification_classes.dup
    original_customizations = described_class.workflow_customizations.dup
    described_class.verification_classes.clear
    described_class.workflow_customizations.clear
    example.run
  ensure
    described_class.verification_classes.replace(original_classes)
    described_class.workflow_customizations.replace(original_customizations)
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

  describe ".selectable_workflows" do
    it "omits customization handlers until that customization is enabled" do
      with_customizations do
        register_test_customization(:community) do |customization|
          customization.authorization("NgoVerify") { |config| config.add_field(:foo, type: :text) }
        end
        organization = create(:organization)

        expect(described_class.selectable_workflows(organization).map(&:name)).not_to include("ngo_verify")

        enable_customization_for(organization, :community)
        expect(described_class.selectable_workflows(organization).map(&:name)).to include("ngo_verify")
      end
    end
  end

  describe ".prune_disabled_handlers" do
    it "drops handlers whose customization is disabled and keeps others" do
      with_customizations do
        register_test_customization(:community) do |customization|
          customization.authorization("NgoVerify") { |config| config.add_field(:foo, type: :text) }
        end
        organization = create(:organization)
        raw = %w(ngo_verify dummy_authorization_handler)

        expect(described_class.prune_disabled_handlers(raw, organization)).to eq(%w(dummy_authorization_handler))
      end
    end

    it "keeps Hash storage used with decidim-ephemeral_participation" do
      with_customizations do
        register_test_customization(:community) do |customization|
          customization.authorization("NgoVerify") { |config| config.add_field(:foo, type: :text) }
        end
        organization = create(:organization)
        raw = {
          "ngo_verify" => { "allow_ephemeral_participation" => false },
          "dummy_authorization_handler" => { "allow_ephemeral_participation" => true }
        }

        expect(described_class.prune_disabled_handlers(raw, organization)).to eq(
          "dummy_authorization_handler" => { "allow_ephemeral_participation" => true }
        )
      end
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

    it "stores workflow customization when declared" do
      handler_name = "bound_verification#{SecureRandom.hex(4)}"
      klass_name = handler_name.camelize

      allow(Decidim::Verifications).to receive(:register_workflow)

      with_customizations do
        register_test_customization(:community)

        described_class.register(handler_name, customization: :community) do |builder|
          builder.add_field(:test_field, type: :text)
        end

        expect(described_class.workflow_customization(handler_name)).to eq(:community)
      end
    ensure
      described_class.workflow_customizations.delete(handler_name)
      described_class.send(:remove_const, klass_name) if described_class.const_defined?(klass_name)
    end
  end
end
