# frozen_string_literal: true

module Decidim
  module CustomUserFields
    module Customizations
      class Customization
        attr_reader :name, :fields, :workflow_handlers

        def initialize(name)
          @name = name.to_sym
          @fields = []
          @workflow_handlers = []
        end

        def label
          I18n.t(
            @name,
            scope: "decidim.custom_user_fields.customizations",
            default: @name.to_s.humanize
          )
        end

        def register_handler!(handler_name)
          @workflow_handlers << handler_name.to_s unless @workflow_handlers.include?(handler_name.to_s)
        end
      end
    end
  end
end
