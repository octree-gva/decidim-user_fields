# frozen_string_literal: true

require 'active_support/concern'

module Decidim
  module CustomUserFields
    # Extra user fields definitions for forms
    module FormsDefinition
      extend ActiveSupport::Concern

      included do |inst|
        include ::Decidim::CustomUserFields::ApplicationHelper
        Decidim::CustomUserFields.custom_fields.each do |field_def|
          field_def.configure_form(inst)
        end
      end

      def map_model(model)
        extended_data = model.extended_data.with_indifferent_access
        field_def.map_model(self, model)
      end
    end
  end
end
