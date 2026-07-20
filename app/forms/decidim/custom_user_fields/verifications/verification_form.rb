# frozen_string_literal: true

module Decidim
  module CustomUserFields
    module Verifications
      class VerificationForm < ::Decidim::AuthorizationHandler
        include ActionView::Helpers::SanitizeHelper
        include ActiveModel::Validations::Callbacks

        before_validation :sanitize_values
        validate :custom_field_validation

        class << self
          attr_accessor :decidim_custom_fields
        end

        def fields
          self.class.decidim_custom_fields
        end

        def custom_field_validation
          data = field_data
          fields.each do |f|
            value = f.sanitized_value(data[f.name])
            f.validate(value, data, errors)
          end
        end

        def metadata
          save_extended_data!
          data = field_data
          super.merge(
            fields.to_h do |field|
              key = field.name
              plain_val = field.sanitized_value(data[key])

              value = field.skip_hashing? ? plain_val : Digest::SHA256.hexdigest(plain_val)
              [key, value]
            end
          )
        end

        def to_partial_path
          "/decidim/custom_user_fields/verification_form"
        end

        private

        # Avoid Decidim::Attributes::Model re-instantiating `user` (STI dual-class crash).
        def field_data
          fields.to_h { |f| [f.name, self[f.name]] }.with_indifferent_access
        end

        def form_user
          @attributes["user"].value_before_type_cast
        end

        def sanitize_values
          fields.each do |field|
            key = field.name
            next unless attribute_names.include?(key.to_s)

            self[key] = field.sanitized_value(self[key])
          end
        end

        def non_extra_fields
          fields.reject { |f| f.type == :extra_field_ref }
        end

        def extra_fields
          fields.select { |f| f.type == :extra_field_ref }
        end

        def save_extended_data!
          user = form_user
          extended_data = user.extended_data.with_indifferent_access
          extra_fields.reject { |field| field.options[:skip_update_on_verified] }.each do |field|
            extended_data[field.storage_name] = field.sanitized_value(self[field.name])
          end
          user.update!(extended_data:)
        end
      end
    end
  end
end
