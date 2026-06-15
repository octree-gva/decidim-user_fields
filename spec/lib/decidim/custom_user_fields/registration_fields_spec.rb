# frozen_string_literal: true

require "spec_helper"

describe Decidim::CustomUserFields::RegistrationFields do
  let(:organization) { create(:organization) }

  describe ".active_registration_fields" do
    it "returns no fields when active_field_set is blank" do
      with_registration_field_sets do
        register_test_field_set(:community) { |set| set.add_field(:foo, type: :dummy) }

        expect(described_class.active_registration_fields(organization)).to eq([])
      end
    end

    it "returns fields for the organization's active field set" do
      with_registration_field_sets do
        register_test_field_set(:community) { |set| set.add_field(:foo, type: :dummy) }
        activate_field_set_for(organization, :community)

        fields = described_class.active_registration_fields(organization)
        expect(fields.map(&:name)).to eq([:foo])
      end
    end

    it "returns no fields when toggle config cannot be read" do
      with_registration_field_sets do
        register_test_field_set(:community) { |set| set.add_field(:foo, type: :dummy) }
        allow(Decidim::Toggle).to receive(:config_for).and_raise(StandardError)

        expect(described_class.active_registration_fields(organization)).to eq([])
      end
    end
  end

  describe ".all_registration_fields" do
    it "returns the union of fields across field sets" do
      with_registration_field_sets do
        Decidim::CustomUserFields.register_field_set(:a) { |set| set.add_field(:foo, type: :dummy) }
        Decidim::CustomUserFields.register_field_set(:b) { |set| set.add_field(:bar, type: :dummy) }

        expect(described_class.all_registration_fields.map(&:name)).to contain_exactly(:foo, :bar)
      end
    end
  end
end
