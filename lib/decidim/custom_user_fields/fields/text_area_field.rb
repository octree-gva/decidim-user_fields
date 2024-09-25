# frozen_string_literal: true

module Decidim
  module CustomUserFields
    module Fields
      class TextAreaField < GenericField
        def configure_form(form)
          form.attribute(name, String)
          validations = {
            presence: required? && {
              message: label(:required)
            }
          }
          if options[:min].present? || options[:max].present?
            min_max_options = {
              wrong_length: -> { label(:bad_length) },
              too_long: -> { label(:too_long) },
              too_short: -> { label(:too_short) }
            }
            min_max_options[:minimum] = options[:min].to_i if options[:min].present?
            min_max_options[:maximum] = options[:max].to_i if options[:max].present?
            validations[:length] = min_max_options
            validations[:allow_blank] = !required?
          end
          form.validates(name, validations)
        end

        def sanitized_value(value)
          stripped_value = (value || "").strip
          return stripped_value if stripped_value.present?

          nil
        end

        def map_model(form, data)
          form[name] = data[name] if data[name].present?
        end

        def form_tag(form_tag)
          field_options = {
            rows: ui_options[:row] || 2,
            label: label(:label),
            help_text: label_exists?(:help_text) && label(:help_text)
          }
          content_tag(
            :div,
            form_tag.text_area(name, **field_options),
            class: class_name
          )
        end
      end
    end
  end
end
