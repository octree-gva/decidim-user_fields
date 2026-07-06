# frozen_string_literal: true

require "spec_helper"

describe Decidim::CustomUserFields do
  describe ".default_email_on_notification" do
    it "defaults to false" do
      expect(described_class.default_email_on_notification).to be(false)
    end
  end

  describe ".configure" do
    it "yields the module configuration" do
      original = described_class.default_email_on_notification
      described_class.configure do |config|
        config.default_email_on_notification = true
      end

      expect(described_class.default_email_on_notification).to be(true)
    ensure
      described_class.default_email_on_notification = original
    end
  end

  describe ".register_customization" do
    it "registers a customization with registration fields" do
      with_customizations do
        described_class.register_customization(:community) do |customization|
          customization.registration_fields do |set|
            set.add_field(:social_url, type: :text, required: false)
          end
        end

        customization = Decidim::CustomUserFields::Customizations.find(:community)
        expect(customization.fields.length).to eq(1)
        expect(customization.fields.first.name).to eq(:social_url)
      end
    end

    it "rejects reserved extended_data keys" do
      with_customizations do
        expect do
          described_class.register_customization(:bad) do |customization|
            customization.registration_fields do |set|
              set.add_field(:nickname, type: :text)
            end
          end
        end.to raise_error(Decidim::CustomUserFields::Error, /reserved/)
      end
    end

    it "registers authorization workflows inside the customization" do
      with_customizations do
        allow(Decidim::Verifications).to receive(:register_workflow)

        described_class.register_customization(:pb2024) do |customization|
          customization.registration_fields { |set| set.add_field(:first_name, type: :text) }
          customization.authorization("PB2024") do |config|
            config.add_field :first_name, type: :extra_field_ref, ref: :first_name
          end
        end

        customization = Decidim::CustomUserFields::Customizations.find(:pb2024)
        expect(customization.workflow_handlers).to include("pb2024")
        expect(Decidim::CustomUserFields::Verifications.workflow_customization("pb2024")).to eq(:pb2024)
      end
    end
  end
end
