# frozen_string_literal: true

require "spec_helper"

describe Decidim::CustomUserFields::Overrides::UpdateAuthorizationsForm do
  let(:organization) { create(:organization, available_authorizations: []) }
  let(:form) do
    Decidim::Toggle::UpdateAuthorizationsForm.from_params(
      organization: {
        available_authorizations: %w(dummy_authorization_handler),
        ephemeral_participation_authorization: "dummy_authorization_handler"
      }
    ).with_context(current_organization: organization)
  end

  describe "#clean_available_authorizations" do
    it "returns an Array from super without wrapping it into a Hash" do
      allow(Decidim::Toggle).to receive(:ephemeral_participation?).and_return(true)
      allow(Decidim::Toggle).to receive(:ephemeral_authorizations_hash?).and_return(false)

      expect(form.clean_available_authorizations).to eq(%w(dummy_authorization_handler))
    end
  end
end
