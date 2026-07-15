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

    it "allows disabling a customization even when its authorizations remain enabled" do
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
  end
end
