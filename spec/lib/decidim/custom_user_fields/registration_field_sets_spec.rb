# frozen_string_literal: true

require "spec_helper"

describe Decidim::CustomUserFields::RegistrationFieldSets do
  describe ".register_field_set" do
    it "stores multiple named field sets" do
      with_registration_field_sets do
        Decidim::CustomUserFields.register_field_set(:community) do |set|
          set.add_field(:social_url, type: :text)
        end
        Decidim::CustomUserFields.register_field_set(:ngos) do |set|
          set.add_field(:organization_name, type: :text)
        end

        expect(described_class.all.length).to eq(2)
        expect(described_class.find(:community).fields.map(&:name)).to eq([:social_url])
      end
    end
  end

  describe Decidim::CustomUserFields::RegistrationFieldSets::RegistrationFieldSet do
    it "exposes a translated label with humanized fallback" do
      field_set = Decidim::CustomUserFields::RegistrationFieldSets::RegistrationFieldSet.new(:community)
      expect(field_set.label).to eq("Community")
    end
  end
end
