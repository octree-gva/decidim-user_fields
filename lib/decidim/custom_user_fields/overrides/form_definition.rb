# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module CustomUserFields
    # Extra user fields definitions for forms
    module FormDefinition
      extend ActiveSupport::Concern

      class_methods do
        def custom_user_field_validation_if(name)
          ->(record) { record.active_custom_field_names.include?(name) }
        end
      end

      included do |inst|
        include ::Decidim::CustomUserFields::ApplicationHelper
        RegistrationFields.all_registration_fields.each do |field_def|
          field_def.configure_form(inst)
        end
      end

      def active_custom_field_names
        org = try(:current_organization)
        return [] unless org

        RegistrationFields.active_registration_fields(org).map(&:name)
      end

      def map_model(model)
        extended_data = model.extended_data.with_indifferent_access
        RegistrationFields.all_registration_fields.each do |field_def|
          field_def.map_model(self, extended_data)
        end
      end
    end
  end
end
