# frozen_string_literal: true

module Decidim
  module CustomUserFields
    module ExtendedData
      module_function

      def validate_params(organization, params, errors: ActiveModel::Errors.new(Object.new))
        params = params.to_h.with_indifferent_access
        active_registration_fields(organization).each do |field_def|
          key = field_def.name
          next unless params.has_key?(key.to_s) || params.has_key?(key)

          raw = params[key.to_s] || params[key]
          value = field_def.sanitized_value(raw)
          field_def.validate(value, params, errors)
        end
        errors
      end

      def build_from_params(organization, params)
        params = params.to_h.with_indifferent_access
        data = {}
        active_registration_fields(organization).each do |field_def|
          key = field_def.name
          next unless params.has_key?(key.to_s) || params.has_key?(key)

          raw = params[key.to_s] || params[key]
          data[key] = field_def.sanitized_value(raw)
        end
        data
      end

      def merge_into(user, organization, params)
        errors = ActiveModel::Errors.new(user)
        validate_params(organization, params, errors:)
        return [false, errors] if errors.any?

        extended_data = (user.extended_data || {}).merge(build_from_params(organization, params))
        if user.update(extended_data:)
          [true, errors]
        else
          [false, user.errors]
        end
      end

      def active_registration_fields(organization)
        RegistrationFields.active_registration_fields(organization)
      end
    end
  end
end
