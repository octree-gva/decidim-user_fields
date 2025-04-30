# frozen_string_literal: true

module Decidim
  module CustomUserFields
    module Verifications
      class Builder
        attr_reader :name
        attr_accessor :fields

        def initialize(name)
          @name = name.to_s
          @fields = []
          @ephemerable = false
        end

        def add_field(field_name, field_definition)
          fields.push(FieldDefinition.new(field_name, field_definition, handler_name))
        end
        
        def ephemerable!
          @ephemerable = true
        end
        
        def ephemerable?
          @ephemerable
        end

        def handler_name
          klass_name.underscore
        end

        def klass_name
          name.camelize.to_s
        end

        def register_workflow!
          Decidim::Verifications.register_workflow(handler_name.to_sym) do |workflow|
            workflow.form = "Decidim::CustomUserFields::Verifications::#{klass_name}"
            klass = Decidim::CustomUserFields::Verifications.create_verification_class(klass_name)
            klass.ephemerable = ephemerable? if klass.respond_to?(:ephemerable=)
            klass.decidim_custom_fields = fields
            fields.map do |field|
              field.configure_form(klass)
            end
          end
        end
      end
    end
  end
end
