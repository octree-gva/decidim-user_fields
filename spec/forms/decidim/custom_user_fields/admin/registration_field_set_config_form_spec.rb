# frozen_string_literal: true

require "spec_helper"

describe Decidim::CustomUserFields::Admin::RegistrationFieldSetConfigForm do
  let(:organization) { create(:organization, available_authorizations: []) }

  describe "validations" do
    it "accepts blank active_field_set as none" do
      with_registration_field_sets do
        register_test_field_set(:community)

        form = described_class.from_params(
          organization: { active_field_set: "" }
        ).with_context(current_organization: organization)

        expect(form).to be_valid
      end
    end

    it "accepts a registered field set" do
      with_registration_field_sets do
        register_test_field_set(:community)

        form = described_class.from_params(
          organization: { active_field_set: "community" }
        ).with_context(current_organization: organization)

        expect(form).to be_valid
      end
    end

    it "rejects unknown field sets" do
      with_registration_field_sets do
        form = described_class.from_params(
          organization: { active_field_set: "missing" }
        ).with_context(current_organization: organization)

        expect(form).not_to be_valid
        expect(form.errors[:active_field_set]).to be_present
      end
    end

    it "rejects field sets incompatible with enabled authorizations" do
      with_registration_field_sets do
        register_test_field_set(:community) { |set| set.add_field(:foo, type: :dummy) }
        register_test_field_set(:ngos) { |set| set.add_field(:bar, type: :dummy) }

        Decidim::CustomUserFields::Verifications.workflow_field_sets["ngo_verify"] = :ngos

        organization.update!(available_authorizations: ["ngo_verify"])

        form = described_class.from_params(
          organization: { active_field_set: "community" }
        ).with_context(current_organization: organization)

        expect(form).not_to be_valid
        expect(form.errors[:active_field_set]).to be_present
      end
    end
  end

  describe ".collection_for_active_field_set" do
    it "lists none plus registered field sets" do
      with_registration_field_sets do
        register_test_field_set(:community)

        options = described_class.collection_for_active_field_set
        expect(options.first).to eq(["", "None"])
        expect(options).to include(["community", kind_of(String)])
      end
    end
  end
end
