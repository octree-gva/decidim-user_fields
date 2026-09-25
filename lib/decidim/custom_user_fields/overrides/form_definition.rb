# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module CustomUserFields
    module FormDefinition
      extend ActiveSupport::Concern

      included do
        include ::Decidim::CustomUserFields::ApplicationHelper
        FormDefinition.setup_form_class(self)
      end

      class << self
        def setup_form_class(form_class)
          RegistrationFields.all_registration_fields.each do |field_def|
            field_def.configure_form(form_class)
          end
        end
      end

      def active_custom_field_names
        org = try(:current_organization)
        return [] unless org

        RegistrationFields.active_registration_fields(org).map(&:name)
      end

      def map_model(model)
        extended_data = (model.extended_data || {}).with_indifferent_access
        org = try(:current_organization) || model.try(:organization)
        active_names = org ? RegistrationFields.active_registration_fields(org).map(&:name) : []
        RegistrationFields.all_registration_fields.each do |field_def|
          next unless active_names.include?(field_def.name)

          field_def.map_model(self, extended_data)
        end
      end
    end
  end
end
