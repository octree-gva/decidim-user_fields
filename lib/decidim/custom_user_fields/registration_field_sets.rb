# frozen_string_literal: true

require "decidim/custom_user_fields/registration_field_sets/registration_field_set"
require "decidim/custom_user_fields/registration_field_sets/builder"

module Decidim
  module CustomUserFields
    module RegistrationFieldSets
      class << self
        def register_field_set(name, &block)
          field_set = RegistrationFieldSet.new(name)
          builder = Builder.new(field_set)
          yield builder
          registry[name.to_sym] = field_set
          field_set
        end

        def find(name)
          return if name.blank?

          registry[name.to_sym]
        end

        def all
          registry.values
        end

        def any?
          registry.any?
        end

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
