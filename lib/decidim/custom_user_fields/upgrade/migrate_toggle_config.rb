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
          return summary unless toggle_available?

          scope.find_each { |record| migrate_record!(record) }
          summary
        end

        private

        attr_reader :dry_run, :migrated, :skipped

        def summary
          { migrated:, skipped: }
        end

        def toggle_available?
          defined?(Decidim::Toggle::OrganizationModuleConfig)
        end

        def scope
          Decidim::Toggle::OrganizationModuleConfig.where(module_name: MODULE_NAME)
        end

        def migrate_record!(record)
          config = (record.config || {}).with_indifferent_access
          legacy_name = config[LEGACY_KEY]
          if legacy_name.blank?
            @skipped += 1
            return
          end

          enabled_key = "#{legacy_name}_enabled"
          next_config = config.except(LEGACY_KEY)
          next_config[enabled_key] = true unless truthy?(next_config[enabled_key])

          if dry_run
            log(record, legacy_name, enabled_key)
          else
            record.update!(config: stringify_config(next_config))
          end

          @migrated += 1
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
