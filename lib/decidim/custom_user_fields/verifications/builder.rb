# frozen_string_literal: true

module Decidim
  module CustomUserFields
    module Verifications
      class Builder
        attr_reader :name
        attr_accessor :fields, :renewable, :time_between_renewals

        def initialize(name)
          @name = name.to_s
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
      end
    end
  end
end
