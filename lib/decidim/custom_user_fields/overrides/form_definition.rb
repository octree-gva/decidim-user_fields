# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module CustomUserFields
    module FormDefinition
      extend ActiveSupport::Concern

      class_methods do
        def custom_user_field_validation_if(name)
          ->(record) { record.active_custom_field_names.include?(name) }
        end

        def apply_registration_fields!(form_class = self)
          RegistrationFields.all_registration_fields.each do |field_def|
            field_def.configure_form(form_class)
          end
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
        extended_data = (model.extended_data || {}).with_indifferent_access
        active_names = active_custom_field_names
        RegistrationFields.all_registration_fields.each do |field_def|
          next unless active_names.include?(field_def.name)

          field_def.map_model(self, extended_data)
        end
      end
    end
  end
end
