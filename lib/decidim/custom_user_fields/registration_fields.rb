# frozen_string_literal: true

module Decidim
  module CustomUserFields
    module RegistrationFields
      RESERVED_EXTENDED_DATA_KEYS = %w(
        nickname
        name
        personal_url
        about
        extended_data
        newsletter_notifications_at
        accepted_tos_version
        locale
        newsletter_notifications
        managed
        deleted_at
        blocked
        confirmed_at
        officialized_at
        confirmed_at
        confirmed_at
      ).freeze

      class << self
        def reserved_key?(name)
          RESERVED_EXTENDED_DATA_KEYS.include?(name.to_s)
        end

        def enabled_customization_names(organization)
          config = toggle_config(organization)
          enabled = enabled_from_customization_flags(config)
          return enabled if enabled.any?

          raw = raw_toggle_config(organization)
          return [] if legacy_config_superseded?(raw)

          legacy_name = raw[:"active_field_set"] || raw["active_field_set"]
          legacy_name.present? ? [legacy_name.to_s] : []
        end

        def active_registration_fields(organization)
          enabled_customization_names(organization).flat_map do |name|
            Customizations.find(name)&.fields || []
          end.uniq(&:name)
        end

        def all_registration_fields
          Customizations.all.flat_map(&:fields).uniq(&:name)
        end

        private

        def toggle_config(organization)
          normalize_toggle_config(fetch_toggle_config(organization))
        rescue StandardError
          {}
        end

        def fetch_toggle_config(organization)
          Decidim::Toggle.config_for(organization, :custom_user_fields)
        end

        def normalize_toggle_config(config)
          if config.respond_to?(:to_config_hash)
            config.to_config_hash.with_indifferent_access
          else
            config.with_indifferent_access
          end
        end

        def raw_toggle_config(organization)
          return {} unless defined?(Decidim::Toggle::OrganizationModuleConfig)

          Decidim::Toggle::OrganizationModuleConfig.find_by(
            decidim_organization_id: organization.id,
            module_name: "custom_user_fields"
          )&.config&.with_indifferent_access || {}
        end

        def customization_enabled?(config, name)
          ActiveModel::Type::Boolean.new.cast(
            config[:"#{name}_enabled"] || config["#{name}_enabled"]
          )
        end

        def enabled_from_customization_flags(config)
          Customizations.all.filter_map do |customization|
            customization.name.to_s if customization_enabled?(config, customization.name)
          end
        end

        def legacy_config_superseded?(config)
          config.keys.any? { |key| key.to_s.end_with?("_enabled") }
        end
      end
    end
  end
end
