# frozen_string_literal: true

module Decidim
  module CustomUserFields
    module AuthorizationFieldSetCompatibility
      class << self
        def incompatible_with_field_set(authorization_names, field_set_key)
          Array(authorization_names).map(&:to_s).select do |handler_name|
            required_set = Verifications.workflow_field_set(handler_name)
            next false unless required_set

            field_set_key.blank? || required_set.to_s != field_set_key.to_s
          end
        end
      end
    end
  end
end
