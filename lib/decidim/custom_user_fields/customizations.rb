# frozen_string_literal: true

require "decidim/custom_user_fields/customizations/customization"
require "decidim/custom_user_fields/customizations/builder"

module Decidim
  module CustomUserFields
    module Customizations
      class << self
        def register(name, &)
          customization = Customization.new(name)
          registry[name.to_sym] = customization
          builder = Builder.new(customization)
          yield builder
          Decidim::CustomUserFields::Admin::CustomizationsConfigForm.register_toggle_attribute!(name)
          customization
        end

        def find(name)
          return if name.blank?

          registry[name.to_sym]
        end

        def all
          registry.values
        end

        delegate :any?, to: :registry

        def clear!
          registry.clear
        end

        private

        def registry
          @registry ||= {}
        end
      end
    end
  end
end
