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
        organization: { enabled_customization: "" }
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

  it "unselects handlers from Hash-shaped available_authorizations" do
    skip "requires decidim-ephemeral_participation" unless ephemeral_participation_gem?

    with_customizations do
      register_test_customization(:community) do |customization|
        customization.authorization("NgoVerify") { |config| config.add_field(:foo, type: :text) }
      end
      enable_customization_for(organization, :community)
      organization.update!(
        available_authorizations: {
          "ngo_verify" => { "allow_ephemeral_participation" => false },
          "dummy_authorization_handler" => { "allow_ephemeral_participation" => true }
        }
      )

      form = Decidim::CustomUserFields::Admin::CustomizationsConfigForm.from_params(
        organization: { enabled_customization: "" }
      ).with_context(current_organization: organization)

      described_class.new(organization, form).call

      raw = organization.reload.read_attribute(:available_authorizations)
      expect(raw).to be_a(Hash)
      expect(raw.keys.map(&:to_s)).to eq(%w(dummy_authorization_handler))
    end
  end
end
