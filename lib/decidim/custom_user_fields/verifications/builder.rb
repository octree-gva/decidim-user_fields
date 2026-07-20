# frozen_string_literal: true

module Decidim
  module CustomUserFields
    module Verifications
      class Builder
        attr_reader :name, :customization
        attr_accessor :fields, :renewable, :time_between_renewals

        def initialize(name, customization: nil)
          @name = name.to_s
          @customization = customization&.to_sym
          @fields = []
          @ephemerable = false
          @renewable = false
          @time_between_renewals = nil
        end

        def renewable!(time_between_renewals = 1.day)
          @renewable = true
          @time_between_renewals = time_between_renewals
        end

        def renewable?
          @renewable
        end

        def add_field(field_name, field_definition)
          field_def = FieldDefinition.new(field_name, field_definition, handler_name)
          field_def.field.customization_name = @customization if field_def.type == :extra_field_ref
          fields.push(field_def)
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
          validate_extra_field_ref_requirements!

          Decidim::Verifications.register_workflow(handler_name.to_sym) do |workflow|
            workflow.form = "Decidim::CustomUserFields::Verifications::#{klass_name}"
            klass = Decidim::CustomUserFields::Verifications.create_verification_class(klass_name)
            workflow.ephemerable = ephemerable? if workflow.respond_to?(:ephemerable=)
            workflow.renewable = renewable? if workflow.respond_to?(:renewable=)
            workflow.time_between_renewals = time_between_renewals unless time_between_renewals.nil?
            workflow.metadata_cell = "decidim/verifications/authorization_metadata"

            klass.decidim_custom_fields = fields
            fields.map do |field|
              field.configure_form(klass)
            end
          end
        end

        private

        def validate_extra_field_ref_requirements!
          uses_extra_field_ref = fields.any? { |field| field.type == :extra_field_ref }
          if uses_extra_field_ref && customization.nil?
            raise Decidim::CustomUserFields::Error,
                  "authorization #{name} must be registered inside a customization when using extra_field_ref fields"
          end

          fields.each do |field|
            field.field.validate_customization_reference! if field.type == :extra_field_ref
          end
        end
      end
    end
  end
end
