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

    it "maps the radio to a single enabled customization" do
      with_customizations do
        register_test_customization(:community)
        register_test_customization(:ngos)

        form = described_class.from_params(
          organization: { enabled_customization: "ngos", community_enabled: true }
        ).with_context(current_organization: organization)

        expect(form).to be_valid
        persist = form.to_h.with_indifferent_access
        expect(persist[:community_enabled]).to be(false)
        expect(persist[:ngos_enabled]).to be(true)
        expect(persist).not_to have_key(:enabled_customization)
        expect(described_class.enabled_customization_names_from(form)).to eq(%w(ngos))
      end
    end

    it "keeps a single flag when params still send multiple booleans" do
      with_customizations do
        register_test_customization(:community)
        register_test_customization(:ngos)

        form = described_class.from_params(
          organization: { community_enabled: true, ngos_enabled: true }
        ).with_context(current_organization: organization)

        form.to_h
        expect(described_class.enabled_customization_names_from(form)).to eq(%w(community))
      end
    end

    it "loads the radio from stored enabled flags" do
      with_customizations do
        register_test_customization(:community)
        enable_customization_for(organization, :community)

        form = described_class.from_model(organization)

        expect(form.enabled_customization).to eq("community")
      end
    end

    it "accepts disabling a customization that still has selected authorizations" do
      with_customizations do
        register_test_customization(:community) do |customization|
          customization.authorization("NgoVerify") { |config| config.add_field(:foo, type: :text) }
        end
        enable_customization_for(organization, :community)
        organization.update!(available_authorizations: ["ngo_verify"])

        form = described_class.from_params(
          organization: { community_enabled: false }
        ).with_context(current_organization: organization)

        expect(form).to be_valid
      end
    end

    it "accepts a valid first_login_mode" do
      with_customizations do
        register_test_customization(:community)

        form = described_class.from_params(
          organization: { first_login_mode: "none", community_enabled: false }
        ).with_context(current_organization: organization)

        expect(form).to be_valid
        expect(form.first_login_mode).to eq("none")
      end
    end

    it "rejects an invalid first_login_mode" do
      with_customizations do
        register_test_customization(:community)

        form = described_class.from_params(
          organization: { first_login_mode: "bogus" }
        ).with_context(current_organization: organization)

        expect(form).not_to be_valid
      end
    end
  end

  describe ".collection_for_first_login_mode" do
    it "returns prompt_authorization and none options" do
      expect(described_class.collection_for_first_login_mode.map(&:first)).to eq(%w(prompt_authorization none))
    end
  end

  describe ".collection_for_enabled_customization" do
    it "returns none plus registered customizations" do
      with_customizations do
        register_test_customization(:community)

        expect(described_class.collection_for_enabled_customization.map(&:first)).to eq(["", "community"])
      end
    end
  end
end
