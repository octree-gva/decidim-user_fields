# frozen_string_literal: true

module Decidim
  module CustomUserFields
    module Toggle
      module AuthorizationsCustomizationValidation
        extend ActiveSupport::Concern

        included do
          validate :authorizations_match_enabled_customizations
        end

        private

        def authorizations_match_enabled_customizations
          org = context&.dig(:current_organization) || try(:current_organization)
          return unless org

          enabled = RegistrationFields.enabled_customization_names(org)
          incompatible = AuthorizationCustomizationCompatibility.incompatible_with_enabled_customizations(
            clean_available_authorizations,
            enabled
          )
          return if incompatible.blank?

          errors.add(
            :available_authorizations,
            I18n.t(
              "incompatible_authorizations",
              scope: "decidim.custom_user_fields.system.customizations",
              authorizations: incompatible.join(", ")
            )
          )
        end
      end
    end
  end
end
