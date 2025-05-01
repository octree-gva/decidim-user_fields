# frozen_string_literal: true

module Decidim
  module CustomUserFields
    module Fields
      class TextField < GenericField
        def configure_form(form)
          form.attribute(name, String)
          validations = {
            presence: required?
          }
          if options[:values_in]
            validations[:inclusion] = {
              in: options[:values_in],
              message: proc do |_, _|
                label(:bad_values)
              end
            }
          end

          if options[:format]
            validations[:format] = {
              with: options[:format],
              message: proc do |_, _|
                label(:bad_format)
              end
            }
          end

          form.validates(name, validations)
        end

        def map_model(form, data)
          form[name] = data[name].strip if data[name].present?
        end

        def sanitized_value(value)
          stripped_value = (value || "").strip
          return stripped_value if stripped_value.present?

          nil
        end

        def form_tag(form_tag)
          form_tag.text_field(
            name,
            label: label(:label),
            help_text: label_exists?(:help_text) && label(:help_text),
            class: class_name,
            label_options: { class: label_class_name }
          )
        end
      end
    end
  end
end
