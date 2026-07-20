# frozen_string_literal: true

require "spec_helper"

describe Decidim::CustomUserFields::I18n::CustomizationKeys do
  describe ".missing" do
    it "has no missing keys for registered scenario customizations in English" do
      expect(described_class.missing(locale: :en)).to eq([])
    end
  end

  describe ".required_keys" do
    it "lists toggle, customization, field, and authorization handler keys" do
      with_customizations do
        Decidim::CustomUserFields.register_customization(:community) do |customization|
          customization.registration_fields do |set|
            set.add_field(:social_url, type: :text, required: false)
          end
          customization.authorization "CommunityGate" do |config|
            config.add_field :social_url, type: :extra_field_ref, ref: :social_url, required: true
          end
        end

        keys = described_class.required_keys

        expect(keys).to include(
          "decidim_toggle.system.custom_user_fields.community_enabled",
          "decidim.custom_user_fields.customizations.community",
          "decidim.custom_user_fields.extended_data.community_social_url.label",
          "decidim.authorization_handlers.community_gate.name",
          "decidim.authorization_handlers.community_gate.explanation",
          "decidim.custom_user_fields.community_gate.social_url.label"
        )
        expect(described_class.missing(locale: :en)).to include(
          "decidim_toggle.system.custom_user_fields.community_enabled",
          "decidim.custom_user_fields.customizations.community",
          "decidim.authorization_handlers.community_gate.name"
        )
      end
    end
  end
end
