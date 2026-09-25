# frozen_string_literal: true

module Decidim
  module CustomUserFields
    module I18n
      # Required translation keys derived from {Customizations} registry.
      # Used by RSpec and the i18n-tasks custom scanner.
      module CustomizationKeys
        module_function

        def required_keys
          Decidim::CustomUserFields::Customizations.all.flat_map do |customization|
            keys_for(customization)
          end.uniq.sort
        end

        def missing(locale: :en)
          required_keys.reject { |key| ::I18n.exists?(key, locale) }
        end

        def keys_for(customization)
          name = customization.name
          keys = [
            "decidim_toggle.system.custom_user_fields.#{name}_enabled",
            "decidim.custom_user_fields.customizations.#{name}"
          ]

          customization.fields.each do |field|
            keys << "decidim.custom_user_fields.extended_data.#{field.name}.label"
          end

          customization.workflow_handlers.each do |handler|
            keys << "decidim.authorization_handlers.#{handler}.name"
            keys << "decidim.authorization_handlers.#{handler}.explanation"
            auth_fields_for(handler).each do |field|
              keys << "decidim.custom_user_fields.#{handler}.#{field.name}.label"
            end
          end

          keys
        end

        def auth_fields_for(handler)
          klass_name = handler.to_s.camelize
          return [] unless Decidim::CustomUserFields::Verifications.const_defined?(klass_name, false)

          klass = Decidim::CustomUserFields::Verifications.const_get(klass_name, false)
          Array(klass.try(:decidim_custom_fields))
        rescue NameError
          []
        end
      end
    end
  end
end
