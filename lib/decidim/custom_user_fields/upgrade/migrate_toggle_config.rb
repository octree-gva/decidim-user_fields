# frozen_string_literal: true

module Decidim
  module CustomUserFields
    module Upgrade
      # One-time migration: decidim-toggle config `active_field_set` → `{name}_enabled`.
      class MigrateToggleConfig
        MODULE_NAME = "custom_user_fields"
        LEGACY_KEY = "active_field_set"

        class << self
          def run(dry_run: false)
            new(dry_run:).run
          end
        end

        def initialize(dry_run: false)
          @dry_run = dry_run
          @migrated = 0
          @skipped = 0
        end

        def run
          scope.find_each { |record| migrate_record!(record) }
          summary
        end

        private

        attr_reader :dry_run, :migrated, :skipped

        def summary
          { migrated:, skipped: }
        end

        def scope
          Decidim::Toggle::OrganizationModuleConfig.where(module_name: MODULE_NAME)
        end

        def migrate_record!(record)
          config = (record.config || {}).with_indifferent_access
          legacy_name = config[LEGACY_KEY]
          return increment_skipped if legacy_name.blank?

          persist_migrated!(record, config, legacy_name)
          @migrated += 1
        end

        def increment_skipped
          @skipped += 1
        end

        def persist_migrated!(record, config, legacy_name)
          enabled_key = "#{legacy_name}_enabled"
          next_config = config.except(LEGACY_KEY)
          next_config[enabled_key] = true unless truthy?(next_config[enabled_key])
          return log(record, legacy_name, enabled_key) if dry_run

          record.update!(config: stringify_config(next_config))
        end

        def stringify_config(config)
          config.to_h.stringify_keys
        end

        def truthy?(value)
          ActiveModel::Type::Boolean.new.cast(value)
        end

        def log(record, legacy_name, enabled_key)
          Rails.logger.debug do
            "[dry-run] org #{record.decidim_organization_id}: " \
              "#{LEGACY_KEY}=#{legacy_name} → #{enabled_key}=true"
          end
        end
      end
    end
  end
end
