# frozen_string_literal: true

module Decidim
  module CustomUserFields
    module AuthorizationCustomizationCompatibility
      class << self
        def incompatible_with_enabled_customizations(authorization_names, enabled_customization_names)
          enabled = Array(enabled_customization_names).map(&:to_s)
          Array(authorization_names).map(&:to_s).select do |handler_name|
            customization = Verifications.workflow_customization(handler_name)
            next false unless customization

            enabled.blank? || !enabled.include?(customization.to_s)
          end
        end

        def blocking_authorizations_for_disabled_customization(organization, customization_name)
          handlers = Verifications.workflow_handlers_for(customization_name)
          Array(organization.available_authorizations).map(&:to_s) & handlers
        end
      end
    end
  end
end
