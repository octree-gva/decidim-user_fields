# frozen_string_literal: true

require "spec_helper"

describe Decidim::CustomUserFields::Admin::CustomizationsConfigForm do
  let(:organization) { create(:organization, available_authorizations: []) }

  describe "validations" do
    it "accepts all customizations disabled" do
      with_customizations do
        register_test_customization(:community)

        form = described_class.from_params(
          organization: { community_enabled: false }
        ).with_context(current_organization: organization)

        expect(form).to be_valid
      end
    end

    it "accepts enabling a registered customization" do
      with_customizations do
        register_test_customization(:community)

        form = described_class.from_params(
          organization: { community_enabled: true }
        ).with_context(current_organization: organization)

        expect(form).to be_valid
      end
    end

    it "rejects disabling a customization with enabled org authorizations" do
      with_customizations do
        register_test_customization(:community) do |customization|
          customization.authorization("NgoVerify") { |config| config.add_field(:foo, type: :text) }
        end
        enable_customization_for(organization, :community)
        organization.update!(available_authorizations: ["ngo_verify"])

        form = described_class.from_params(
          organization: { community_enabled: false }
        ).with_context(current_organization: organization)

        expect(form).not_to be_valid
        expect(form.errors[:community_enabled]).to be_present
      end
    end

    it "rejects when enabled authorizations require a disabled customization" do
      with_customizations do
        register_test_customization(:community) do |customization|
          customization.registration_fields { |set| set.add_field(:foo, type: :dummy) }
        end
        register_test_customization(:ngos) do |customization|
          customization.authorization("NgoVerify") { |config| config.add_field(:foo, type: :text) }
        end
        enable_customization_for(organization, :community)

        organization.update!(available_authorizations: ["ngo_verify"])

        form = described_class.from_params(
          organization: { community_enabled: true, ngos_enabled: false }
        ).with_context(current_organization: organization)

        expect(form.incompatible_authorization_names).to eq(%w(ngo_verify))
      end
    end
  end

  describe "#incompatible_authorization_names" do
    it "returns empty without organization context" do
      with_customizations do
        register_test_customization(:community)

        form = described_class.from_params(organization: { community_enabled: true })

        expect(form.incompatible_authorization_names).to eq([])
      end
    end
  end

  describe "previous config" do
    it "falls back to empty config when toggle cannot be read" do
      with_customizations do
        register_test_customization(:community)
        enable_customization_for(organization, :community)
        allow(Decidim::Toggle).to receive(:config_for).and_raise(StandardError)

        form = described_class.from_params(
          organization: { community_enabled: false }
        ).with_context(current_organization: organization)

        expect(form).to be_valid
      end
    end
  end
end
