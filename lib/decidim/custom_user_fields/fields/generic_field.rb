# frozen_string_literal: true

module Decidim
  module CustomUserFields
    module Fields
      class GenericField
        include ActionView::Helpers::TagHelper

        delegate :name, :type, :handler_name, to: :definition

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

        # Key used in user.extended_data (overridden by ExtraFieldRefField).
        def storage_name
          name
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

        def apply_form_validations(form, validations)
          validations = validations.dup
          if validations.has_key?(:presence)
            validations.delete(:presence) if validations[:presence] == false
          elsif required?
            validations[:presence] = true
          end
          return if validations.blank?

          field_name = name
          validation_options = validations.dup
          if registration_form?(form)
            validation_options[:if] = lambda { |record|
              record.active_custom_field_names.include?(field_name)
            }
          end
          form.validates(name, **validation_options)
        end

        def registration_form?(form)
          form.included_modules.include?(Decidim::CustomUserFields::FormDefinition)
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
