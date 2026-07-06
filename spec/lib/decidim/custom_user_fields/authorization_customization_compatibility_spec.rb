# frozen_string_literal: true

require "spec_helper"

describe Decidim::CustomUserFields::AuthorizationCustomizationCompatibility do
  describe ".incompatible_with_enabled_customizations" do
    it "returns empty when authorizations have no customization binding" do
      expect(described_class.incompatible_with_enabled_customizations(%w(dummy), %w(community))).to eq([])
    end

    it "flags authorizations bound to a disabled customization" do
      Decidim::CustomUserFields::Verifications.workflow_customizations["ngo_verify"] = :ngos

      expect(described_class.incompatible_with_enabled_customizations(%w(ngo_verify), %w(community))).to eq(%w(ngo_verify))
    ensure
      Decidim::CustomUserFields::Verifications.workflow_customizations.delete("ngo_verify")
    end

    it "allows matching enabled customization" do
      Decidim::CustomUserFields::Verifications.workflow_customizations["ngo_verify"] = :ngos

      expect(described_class.incompatible_with_enabled_customizations(%w(ngo_verify), %w(ngos))).to eq([])
    ensure
      Decidim::CustomUserFields::Verifications.workflow_customizations.delete("ngo_verify")
    end

    it "flags bound authorizations when no customization is enabled" do
      Decidim::CustomUserFields::Verifications.workflow_customizations["ngo_verify"] = :ngos

      expect(described_class.incompatible_with_enabled_customizations(%w(ngo_verify), [])).to eq(%w(ngo_verify))
    ensure
      Decidim::CustomUserFields::Verifications.workflow_customizations.delete("ngo_verify")
    end
  end

  describe ".blocking_authorizations_for_disabled_customization" do
    it "returns org authorizations that belong to the customization" do
      organization = create(:organization, available_authorizations: %w(ngo_verify other_verify))
      Decidim::CustomUserFields::Verifications.workflow_customizations["ngo_verify"] = :ngos
      Decidim::CustomUserFields::Verifications.workflow_customizations["other_verify"] = :ngos

      expect(
        described_class.blocking_authorizations_for_disabled_customization(organization, :ngos)
      ).to contain_exactly("ngo_verify", "other_verify")
    ensure
      Decidim::CustomUserFields::Verifications.workflow_customizations.delete("ngo_verify")
      Decidim::CustomUserFields::Verifications.workflow_customizations.delete("other_verify")
    end
  end
end
