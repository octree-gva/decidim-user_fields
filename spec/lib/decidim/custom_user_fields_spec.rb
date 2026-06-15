# frozen_string_literal: true

require "spec_helper"

describe Decidim::CustomUserFields do
  describe ".default_email_on_notification" do
    it "defaults to false" do
      expect(described_class.default_email_on_notification).to be(false)
    end
  end

  describe ".register_field_set" do
    it "registers a field set with fields" do
      with_registration_field_sets do
        described_class.register_field_set(:community) do |set|
          set.add_field(:social_url, type: :text, required: false)
        end

        field_set = Decidim::CustomUserFields::RegistrationFieldSets.find(:community)
        expect(field_set.fields.length).to eq(1)
        expect(field_set.fields.first.name).to eq(:social_url)
      end
    end

    it "rejects reserved extended_data keys" do
      with_registration_field_sets do
        expect do
          described_class.register_field_set(:bad) do |set|
            set.add_field(:interested_scopes, type: :text)
          end
        end.to raise_error(Decidim::CustomUserFields::Error, /reserved/)
      end
    end
  end
end
