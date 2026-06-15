# frozen_string_literal: true

module Decidim
  module CustomUserFields
    module Toggle
      module AuthorizationsFieldSetValidation
        extend ActiveSupport::Concern

        included do
          validate :authorizations_match_active_field_set
        end

        private

        def authorizations_match_active_field_set
          org = context&.dig(:current_organization) || try(:current_organization)
          return unless org

          field_set_key = Decidim::Toggle.config_for(org, :custom_user_fields).active_field_set.to_s
          incompatible = AuthorizationFieldSetCompatibility.incompatible_with_field_set(
            clean_available_authorizations,
            field_set_key
          )
          return if incompatible.blank?

          errors.add(
            :available_authorizations,
            I18n.t(
              "incompatible_authorizations",
              scope: "decidim.custom_user_fields.system.field_sets",
              authorizations: incompatible.join(", ")
            )
          )
        end
      end
    end
  end
end
