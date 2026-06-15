# frozen_string_literal: true

module Decidim
  module CustomUserFields
    module RegistrationFieldSets
      class RegistrationFieldSet
        attr_reader :name, :fields

        def initialize(name)
          @name = name.to_sym
          @fields = []
        end

        def label
          I18n.t(
            @name,
            scope: "decidim.custom_user_fields.field_sets",
            default: @name.to_s.humanize
          )
        end
      end
    end
  end
end
