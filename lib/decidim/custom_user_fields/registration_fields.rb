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
      ).freeze

      FIRST_LOGIN_MODES = %w(prompt_authorization none).freeze
      DEFAULT_FIRST_LOGIN_MODE = "prompt_authorization"

      class << self
        def reserved_key?(name)
          RESERVED_EXTENDED_DATA_KEYS.include?(name.to_s)
        end

        def first_login_mode(organization)
          value = raw_toggle_config(organization)[:first_login_mode].presence
          return DEFAULT_FIRST_LOGIN_MODE if value.blank? || FIRST_LOGIN_MODES.exclude?(value.to_s)

          value.to_s
        end

        def prompt_authorization_on_first_login?(organization)
          first_login_mode(organization) == DEFAULT_FIRST_LOGIN_MODE
        end

        def enabled_customization_names(organization)
          config = raw_toggle_config(organization)
          from_enabled_customization_key(config) || from_legacy_enabled_flags(config)
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

        def raw_toggle_config(organization)
          Decidim::Toggle::OrganizationModuleConfig.find_by(
            decidim_organization_id: organization.id,
            module_name: "custom_user_fields"
          )&.config&.with_indifferent_access || {}
        end

        def from_enabled_customization_key(config)
          return unless config.has_key?(:enabled_customization)

          name = config[:enabled_customization].to_s
          Customizations.find(name) ? [name] : []
        end

        def from_legacy_enabled_flags(config)
          enabled = enabled_from_customization_flags(config)
          return enabled.first(1) if enabled.any?
          return [] if legacy_config_superseded?(config)

          Array(config[:active_field_set].presence&.to_s)
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
