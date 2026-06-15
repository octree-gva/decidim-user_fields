# frozen_string_literal: true

require "spec_helper"

describe Decidim::Toggle::UpdateAuthorizationsForm do
  let(:organization) { create(:organization, available_authorizations: []) }
  let(:handler_name) { "dummy_authorization_handler" }

  before do
    Decidim::Toggle::UpdateAuthorizationsForm.include(
      Decidim::CustomUserFields::Toggle::AuthorizationsFieldSetValidation
    )
  end

  describe "field set compatibility validation" do
    it "rejects authorizations incompatible with the organization active field set" do
      with_registration_field_sets do
        register_test_field_set(:community)
        register_test_field_set(:ngos)
        activate_field_set_for(organization, :community)
        Decidim::CustomUserFields::Verifications.workflow_field_sets[handler_name] = :ngos

        form = described_class.from_params(
          organization: { available_authorizations: [handler_name] }
        ).with_context(current_organization: organization)

        expect(form).not_to be_valid
        expect(form.errors[:available_authorizations]).to be_present
      end
    end

    it "accepts authorizations matching the active field set" do
      with_registration_field_sets do
        register_test_field_set(:ngos)
        activate_field_set_for(organization, :ngos)
        Decidim::CustomUserFields::Verifications.workflow_field_sets[handler_name] = :ngos

        form = described_class.from_params(
          organization: { available_authorizations: [handler_name] }
        ).with_context(current_organization: organization)

        expect(form).to be_valid
      end
    end
  end
end
