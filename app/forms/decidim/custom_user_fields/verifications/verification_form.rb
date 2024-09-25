# frozen_string_literal: true

module Decidim
  module CustomUserFields
    module Verifications
      class VerificationForm < ::Decidim::AuthorizationHandler
        include ActionView::Helpers::SanitizeHelper
        include ActiveModel::Validations::Callbacks

        before_validation :sanitize_values

        attribute :user, ::Decidim::User
        validate :custom_field_validation
        class << self
          attr_accessor :decidim_custom_fields
        end

        def fields
          self.class.decidim_custom_fields
        end

        def custom_field_validation
          fields.map do |f|
            value = f.sanitized_value(attributes[f.name])
            f.validate(value, attributes, errors)
          end
        end

        def metadata
          save_extended_data!
          super.merge(
            fields.to_h do |field|
              key = field.name
              plain_val = field.sanitized_value(attributes[key])

              value = field.skip_hashing? ? plain_val : Digest::SHA256.hexdigest(plain_val)
              [key, value]
            end
          )
        end

        def to_partial_path
          "/decidim/custom_user_fields/verification_form"
        end

        private

        def sanitize_values
          fields.map do |field|
            key = field.name
            self[key] = field.sanitized_value(attributes[key]) if attribute_names.include?(key.to_s)
          end
        end

        def extra_fields
          fields.select { |f| f.type == :extra_field_ref }
        end

        def non_extra_fields
          fields.reject { |f| f.type == :extra_field_ref }
        end

        def save_extended_data!
          user = attributes["user"]
          extended_data = user.extended_data.with_indifferent_access
          extra_fields.reject { |field| field.options[:skip_update_on_verified] }.each do |field|
            extended_data[field.name] = field.sanitized_value(attributes[field.name])
          end
          user.update!(extended_data: extended_data)
        end
      end
    end
  end
end
