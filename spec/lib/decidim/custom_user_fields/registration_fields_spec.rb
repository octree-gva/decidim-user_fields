# frozen_string_literal: true

require "spec_helper"

describe Decidim::CustomUserFields::RegistrationFields do
  let(:organization) { create(:organization) }

  describe ".enabled_customization_names" do
    it "returns empty when no customization is enabled" do
      with_customizations do
        register_test_customization(:community)

        expect(described_class.enabled_customization_names(organization)).to eq([])
      end
    end

    it "returns enabled customization names" do
      with_customizations do
        register_test_customization(:community)
        register_test_customization(:ngos)
        enable_customization_for(organization, :community)

        expect(described_class.enabled_customization_names(organization)).to eq(%w(community))
      end
    end

    it "falls back to active_field_set when no customization flags exist" do
      with_customizations do
        register_test_customization(:default) do |customization|
          customization.registration_fields { |set| set.add_field(:foo, type: :dummy) }
        end
        Decidim::Toggle.save_config!(organization, :custom_user_fields, { "active_field_set" => "default" }, merge: false)

        expect(described_class.enabled_customization_names(organization)).to eq(%w(default))
      end
    end

    it "does not fall back to active_field_set when customization flags exist" do
      with_customizations do
        register_test_customization(:default)
        Decidim::Toggle.save_config!(
          organization,
          :custom_user_fields,
          { "active_field_set" => "default", "default_enabled" => false },
          merge: false
        )

        expect(described_class.enabled_customization_names(organization)).to eq([])
      end
    end

    it "returns empty when toggle config cannot be read" do
      with_customizations do
        register_test_customization(:community)
        allow(Decidim::Toggle).to receive(:config_for).and_raise(StandardError)

        expect(described_class.enabled_customization_names(organization)).to eq([])
      end
    end
  end

  describe ".active_registration_fields" do
    it "returns no fields when no customization is enabled" do
      with_customizations do
        register_test_customization(:community) do |customization|
          customization.registration_fields { |set| set.add_field(:foo, type: :dummy) }
        end

        expect(described_class.active_registration_fields(organization)).to eq([])
      end
    end

    it "returns fields from all enabled customizations" do
      with_customizations do
        register_test_customization(:community) do |customization|
          customization.registration_fields { |set| set.add_field(:foo, type: :dummy) }
        end
        register_test_customization(:ngos) do |customization|
          customization.registration_fields { |set| set.add_field(:bar, type: :dummy) }
        end
        enable_customization_for(organization, :community, :ngos)

        expect(described_class.enabled_customization_names(organization)).to eq(%w(community ngos))
        fields = described_class.active_registration_fields(organization)
        expect(fields.map(&:name)).to contain_exactly(:community_foo, :ngos_bar)
      end
    end
  end

  describe ".all_registration_fields" do
    it "returns the union of fields across customizations" do
      with_customizations do
        register_test_customization(:a) do |customization|
          customization.registration_fields { |set| set.add_field(:foo, type: :dummy) }
        end
        register_test_customization(:b) do |customization|
          customization.registration_fields { |set| set.add_field(:bar, type: :dummy) }
        end

        expect(described_class.all_registration_fields.map(&:name)).to contain_exactly(:a_foo, :b_bar)
      end
    end
  end
end
