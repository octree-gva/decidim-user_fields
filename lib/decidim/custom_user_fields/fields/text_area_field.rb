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
              wrong_length: proc do
                label(:bad_length)
              end,
              too_long: proc do
                label(:too_long)
              end,
              too_short: proc do
                label(:too_short)
              end
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
            help_text: label_exists?(:help_text) && label(:help_text),
            label_options: { class: label_class_name },
            class: class_name
          }
          form_tag.text_area(name, **field_options)
        end
      end
    end
  end
end
