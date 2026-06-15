# frozen_string_literal: true

module Decidim
  module CustomUserFields
    module RegistrationFieldSets
      class Builder
        def initialize(field_set)
          @field_set = field_set
        end

        def add_field(field_name, field_definition)
          field_name = field_name.to_sym
          if RegistrationFields.reserved_key?(field_name)
            raise Decidim::CustomUserFields::Error,
                  "Field name #{field_name} is reserved by decidim-core extended_data"
          end

          @field_set.fields.push(
            FieldDefinition.new(field_name, field_definition, "extended_data")
          )
        end
      end
    end
  end
end
