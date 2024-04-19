module Decidim
  module CustomUserFields
    module Fields
      class GenericField
        extend Forwardable
        include ActionView::Helpers::TagHelper

        def_delegators :@definition, :name, :type

        attr_reader :definition, :options
        def initialize(definition, options)
          @definition = definition
          @options = options
        end

        def configure_form(_form)
          raise Error, "Configure Form is not implemented for #{definition.type} type"
        end

        def map_model(_form, _model_data)
          raise Error, "Map Model is not implemented for #{definition.type} type"
        end

        def form_tag(_form)
          raise Error, "Form Tag is not implemented for #{definition.type} type"
        end

        def class_name
          class_specifier = name.to_s.underscore
          "field field--#{type} field--#{class_specifier}"
        end

        def required?
          options[:required].present? && options[:required]
        end
      end
    end
  end
end
