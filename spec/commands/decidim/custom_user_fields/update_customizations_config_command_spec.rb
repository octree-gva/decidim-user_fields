# frozen_string_literal: true

require "spec_helper"

describe Decidim::CustomUserFields::UpdateCustomizationsConfigCommand do
  let(:organization) { create(:organization, available_authorizations: %w(ngo_verify dummy_authorization_handler)) }

  it "unselects handlers when their customization is disabled" do
    with_customizations do
      register_test_customization(:community) do |customization|
        customization.authorization("NgoVerify") { |config| config.add_field(:foo, type: :text) }
      end
      enable_customization_for(organization, :community)

      form = Decidim::CustomUserFields::Admin::CustomizationsConfigForm.from_params(
        organization: { community_enabled: false }
      ).with_context(current_organization: organization)

      outcomes = []
      command = described_class.new(organization, form)
      command.on(:ok) { outcomes << :ok }
      command.on(:invalid) { outcomes << :invalid }
      command.call

      expect(outcomes).to eq([:ok])
      expect(organization.reload.available_authorizations).to eq(%w(dummy_authorization_handler))
    end
  end
end
