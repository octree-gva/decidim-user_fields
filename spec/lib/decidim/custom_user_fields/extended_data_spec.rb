# frozen_string_literal: true

require "spec_helper"

describe Decidim::CustomUserFields::ExtendedData do
  describe ".validate_params" do
    it "rejects text values outside values_in" do
      with_customizations do
        organization = create(:organization)
        register_test_customization(:default) do |customization|
          customization.registration_fields do |set|
            set.add_field(:role, type: :text, values_in: %w(member admin))
          end
        end
        enable_customization_for(organization, :default)

        errors = described_class.validate_params(organization, { default_role: "guest" })

        expect(errors.messages[:default_role]).to be_present
      end
    end

    it "accepts text values inside values_in" do
      with_customizations do
        organization = create(:organization)
        register_test_customization(:default) do |customization|
          customization.registration_fields do |set|
            set.add_field(:role, type: :text, values_in: %w(member admin))
          end
        end
        enable_customization_for(organization, :default)

        errors = described_class.validate_params(organization, { default_role: "member" })

        expect(errors).to be_empty
      end
    end
  end

  describe ".merge_into" do
    it "persists sanitized custom field values on the user" do
      with_customizations do
        organization = create(:organization)
        user = create(:user, organization:, extended_data: {})
        register_test_customization(:default) do |customization|
          customization.registration_fields do |set|
            set.add_field(:note, type: :text, values_in: %w(a b))
          end
        end
        enable_customization_for(organization, :default)

        success, = described_class.merge_into(user, organization, { default_note: "a" })

        expect(success).to be(true)
        expect(user.reload.extended_data["default_note"]).to eq("a")
      end
    end

    it "returns validation errors instead of raising" do
      with_customizations do
        organization = create(:organization)
        user = create(:user, organization:, extended_data: {})
        register_test_customization(:default) do |customization|
          customization.registration_fields do |set|
            set.add_field(:note, type: :text, values_in: %w(a b))
          end
        end
        enable_customization_for(organization, :default)

        success, errors = described_class.merge_into(user, organization, { default_note: "c" })

        expect(success).to be(false)
        expect(errors[:default_note]).to be_present
        expect(user.reload.extended_data).to eq({})
      end
    end
  end
end
