# frozen_string_literal: true

require "spec_helper"

describe Decidim::CustomUserFields::Verifications do
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
  end
end
