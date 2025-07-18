# frozen_string_literal: true

module Decidim
  module CustomUserFields
    module Fields
      class GenericField
        extend Forwardable
        include ActionView::Helpers::TagHelper

        def_delegators :@definition, :name, :type, :handler_name

        attr_reader :definition
        attr_accessor :options

        def initialize(definition, options)
          @definition = definition
          @options = options
        end

        def validate(_value, _data, _errors); end

        def sanitized_value(raw_value)
          raw_value
        end

        def skip_hashing?
          options[:skip_hashing].present?
        end

        def ui_options
          options[:ui] || {}
        end

        def configure_form(_form)
          raise Error, "Configure Form is not implemented for #{definition.type} type"
        end

        def configure_settings(_settings)
          raise Error, "Configure Settings is not implemented for #{definition.type} type"
        end

        def map_model(_form, _model_data)
          raise Error, "Map Model is not implemented for #{definition.type} type"
        end

        def form_tag(_form, _custom_label = nil)
          raise Error, "Form Tag is not implemented for #{definition.type} type"
        end

        def class_name
          @class_name ||= [
            "field",
            class_modifer(type),
            class_modifer(name.to_s.underscore)
          ].join(" ")
        end

        def label_class_name
          @label_class_name ||= [
            "field_label",
            class_modifer(type, "field_label"),
            class_modifer(name.to_s.underscore, "field_label")
          ].join(" ")
        end

        def class_modifer(modifier, block = "field")
          "#{block}--#{modifier}"
        end

        def label_exists?(label)
          I18n.exists?(i18n_handler_label(label))
        end

        def label(label)
          i18n_identifier = i18n_handler_label(label)
          unless I18n.exists?(i18n_identifier)
            Rails.logger.error("Missing #{i18n_handler_label(label)}")
            return i18n_identifier
          end

          I18n.t(
            i18n_identifier,
            default: i18n_identifier
          )
        end

        def required?
          options[:required].present? && options[:required]
        end

        def i18n_context
          @i18n_context ||= "decidim.custom_user_fields.#{handler_name}"
        end

        attr_writer :i18n_context

        private

        def i18n_handler_label(label)
          "#{i18n_context}.#{name}.#{label}"
        end
      end
    end
  end
end
