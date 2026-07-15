# frozen_string_literal: true

module Decidim
  module CustomUserFields
    module Customizations
      class Builder
        def initialize(customization)
          @customization = customization
        end

        def registration_fields(&block)
          field_builder = RegistrationFieldsBuilder.new(@customization)
          yield field_builder
        end

        def authorization(name, &block)
          Decidim::CustomUserFields::Verifications.register(name, customization: @customization.name, &block)
        end
      end

      class RegistrationFieldsBuilder
        def initialize(customization)
          @customization = customization
        end

        def add_field(field_name, field_definition)
          if RegistrationFields.reserved_key?("#{field_name}".to_sym)
            raise Decidim::CustomUserFields::Error,
                  "Field name #{field_name} is reserved by decidim-core extended_data"
          end
          field_name = CustomizationFieldNaming.prefixed(@customization.name, field_name)

          @customization.fields.push(
            FieldDefinition.new(field_name, field_definition, "extended_data")
          )
        end
      end
    end
  end
end
