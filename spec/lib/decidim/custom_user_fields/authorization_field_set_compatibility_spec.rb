# frozen_string_literal: true

require "spec_helper"

describe Decidim::CustomUserFields::AuthorizationFieldSetCompatibility do
  describe ".incompatible_with_field_set" do
    it "returns empty when authorizations have no field_set binding" do
      expect(described_class.incompatible_with_field_set(%w(dummy), "community")).to eq([])
    end

    it "flags authorizations bound to a different field set" do
      Decidim::CustomUserFields::Verifications.workflow_field_sets["ngo_verify"] = :ngos

      expect(described_class.incompatible_with_field_set(%w(ngo_verify), "community")).to eq(%w(ngo_verify))
    ensure
      Decidim::CustomUserFields::Verifications.workflow_field_sets.delete("ngo_verify")
    end

    it "allows matching field set" do
      Decidim::CustomUserFields::Verifications.workflow_field_sets["ngo_verify"] = :ngos

      expect(described_class.incompatible_with_field_set(%w(ngo_verify), "ngos")).to eq([])
    ensure
      Decidim::CustomUserFields::Verifications.workflow_field_sets.delete("ngo_verify")
    end

    it "flags bound authorizations when org field set is blank" do
      Decidim::CustomUserFields::Verifications.workflow_field_sets["ngo_verify"] = :ngos

      expect(described_class.incompatible_with_field_set(%w(ngo_verify), "")).to eq(%w(ngo_verify))
    ensure
      Decidim::CustomUserFields::Verifications.workflow_field_sets.delete("ngo_verify")
    end
  end
end
