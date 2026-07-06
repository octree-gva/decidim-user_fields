# frozen_string_literal: true

require "spec_helper"

describe Decidim::CustomUserFields::Upgrade::MigrateToggleConfig do
  let(:organization) { create(:organization) }

  def save_toggle_config!(config)
    Decidim::Toggle.save_config!(organization, :custom_user_fields, config, merge: false)
  end

  describe ".run" do
    it "migrates active_field_set to {name}_enabled and removes the legacy key" do
      save_toggle_config!("active_field_set" => "default", "other" => "keep")

      result = described_class.run

      expect(result).to eq(migrated: 1, skipped: 0)
      record = Decidim::Toggle::OrganizationModuleConfig.find_by!(
        decidim_organization_id: organization.id,
        module_name: "custom_user_fields"
      )
      expect(record.config["default_enabled"]).to be(true)
      expect(record.config["other"]).to eq("keep")
      expect(record.config).not_to have_key("active_field_set")
    end

    it "skips rows without active_field_set" do
      save_toggle_config!("default_enabled" => true)

      result = described_class.run

      expect(result).to eq(migrated: 0, skipped: 1)
    end

    it "is idempotent when active_field_set was already migrated" do
      save_toggle_config!("default_enabled" => true)

      expect(described_class.run).to eq(migrated: 0, skipped: 1)
      expect(described_class.run).to eq(migrated: 0, skipped: 1)
    end

    it "does not write when DRY_RUN is set" do
      save_toggle_config!("active_field_set" => "community")

      described_class.run(dry_run: true)

      record = Decidim::Toggle::OrganizationModuleConfig.find_by!(
        decidim_organization_id: organization.id,
        module_name: "custom_user_fields"
      )
      expect(record.config["active_field_set"]).to eq("community")
      expect(record.config["community_enabled"]).to be_nil
    end
  end
end
