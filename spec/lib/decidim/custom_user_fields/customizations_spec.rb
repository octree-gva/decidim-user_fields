# frozen_string_literal: true

require "spec_helper"

describe Decidim::CustomUserFields::Customizations do
  describe ".register" do
    it "stores named customizations with registration fields" do
      with_customizations do
        Decidim::CustomUserFields.register_customization(:community) do |customization|
          customization.registration_fields do |set|
            set.add_field(:social_url, type: :text)
          end
        end

        expect(described_class.all.length).to eq(1)
        expect(described_class.find(:community).fields.map(&:name)).to eq([:social_url])
      end
    end

    it "registers toggle attributes on the admin form" do
      with_customizations do
        Decidim::CustomUserFields.register_customization(:community) do |customization|
          customization.registration_fields { |set| set.add_field(:social_url, type: :text) }
        end

        expect(
          Decidim::CustomUserFields::Admin::CustomizationsConfigForm.attribute_types
        ).to have_key("community_enabled")
      end
    end
  end

  describe Decidim::CustomUserFields::Customizations::Customization do
    it "exposes a translated label with humanized fallback" do
      customization = Decidim::CustomUserFields::Customizations::Customization.new(:community)
      expect(customization.label).to eq("Community")
    end
  end
end
