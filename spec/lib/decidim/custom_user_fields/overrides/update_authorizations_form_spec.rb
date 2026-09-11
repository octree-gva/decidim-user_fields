# frozen_string_literal: true

require "spec_helper"

describe Decidim::CustomUserFields::Overrides::UpdateAuthorizationsForm do
  let(:organization) { create(:organization, available_authorizations: []) }

  def form_for(available)
    Decidim::Toggle::UpdateAuthorizationsForm.from_params(
      organization: { available_authorizations: available }
    ).with_context(current_organization: organization)
  end

  describe "#collection_for_available_authorizations" do
    it "omits handlers bound to a disabled customization" do
      with_customizations do
        register_test_customization(:community) do |customization|
          customization.authorization("NgoVerify") { |config| config.add_field(:foo, type: :text) }
        end

        names = form_for([]).collection_for_available_authorizations.map(&:first)
        expect(names).not_to include("ngo_verify")
        expect(names).to include("dummy_authorization_handler")
      end
    end

    it "includes handlers once their customization is enabled" do
      with_customizations do
        register_test_customization(:community) do |customization|
          customization.authorization("NgoVerify") { |config| config.add_field(:foo, type: :text) }
        end
        enable_customization_for(organization, :community)

        names = form_for([]).collection_for_available_authorizations.map(&:first)
        expect(names).to include("ngo_verify")
      end
    end
  end

  describe "#clean_available_authorizations" do
    it "leaves Hash persistence to Toggle when ephemeral participation is installed" do
      skip "requires decidim-ephemeral_participation" unless ephemeral_participation_gem?

      form = Decidim::Toggle::UpdateAuthorizationsForm.from_params(
        organization: {
          available_authorizations: %w(dummy_authorization_handler),
          ephemeral_participation_authorization: "dummy_authorization_handler"
        }
      ).with_context(current_organization: organization)

      expect(form.clean_available_authorizations).to eq(
        "dummy_authorization_handler" => { "allow_ephemeral_participation" => true }
      )
    end
  end
end
