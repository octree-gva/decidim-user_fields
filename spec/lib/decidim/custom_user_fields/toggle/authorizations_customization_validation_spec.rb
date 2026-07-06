# frozen_string_literal: true

require "spec_helper"

describe Decidim::Toggle::UpdateAuthorizationsForm do
  let(:organization) { create(:organization, available_authorizations: []) }
  let(:handler_name) { "dummy_authorization_handler" }

  before do
    Decidim::Toggle::UpdateAuthorizationsForm.include(
      Decidim::CustomUserFields::Toggle::AuthorizationsCustomizationValidation
    )
  end

  describe "customization compatibility validation" do
    it "rejects authorizations from disabled customizations" do
      with_customizations do
        register_test_customization(:community)
        register_test_customization(:ngos)
        enable_customization_for(organization, :community)
        Decidim::CustomUserFields::Verifications.workflow_customizations[handler_name] = :ngos

        form = described_class.from_params(
          organization: { available_authorizations: [handler_name] }
        ).with_context(current_organization: organization)

        expect(form).not_to be_valid
        expect(form.errors[:available_authorizations]).to be_present
      end
    end

    it "accepts authorizations from enabled customizations" do
      with_customizations do
        register_test_customization(:ngos)
        enable_customization_for(organization, :ngos)
        Decidim::CustomUserFields::Verifications.workflow_customizations[handler_name] = :ngos

        form = described_class.from_params(
          organization: { available_authorizations: [handler_name] }
        ).with_context(current_organization: organization)

        expect(form).to be_valid
      end
    end

    it "ignores authorizations not managed by custom user fields" do
      with_customizations do
        register_test_customization(:community)
        enable_customization_for(organization, :community)

        form = described_class.from_params(
          organization: { available_authorizations: [handler_name] }
        ).with_context(current_organization: organization)

        expect(form).to be_valid
      end
    end
  end
end
