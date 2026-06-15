# frozen_string_literal: true

module Decidim
  module CustomUserFields
    module RegistrationFields
      RESERVED_EXTENDED_DATA_KEYS = %w(
        interested_scopes
        user_name
        document_number
        phone
        verified_at
        rejected_at
      ).freeze

      class << self
        def reserved_key?(name)
          RESERVED_EXTENDED_DATA_KEYS.include?(name.to_s)
        end

        def active_registration_fields(organization)
          key = active_field_set_key(organization)
          return [] if key.blank?

          RegistrationFieldSets.find(key)&.fields || []
        end

        def all_registration_fields
          RegistrationFieldSets.all.flat_map(&:fields).uniq(&:name)
        end

        private

        def active_field_set_key(organization)
          Decidim::Toggle.config_for(organization, :custom_user_fields).active_field_set.to_s
        rescue StandardError
          ""
        end
      end
    end
  end
end
