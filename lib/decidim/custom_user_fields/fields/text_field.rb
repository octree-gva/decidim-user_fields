module Decidim
  module CustomUserFields
    module Fields
      class TextField < GenericField
        def configure_form(form)
          form.attribute(name, String)
          validations = {
            presence: required?
          }
          validations[:inclusion] = {
            in: options[:values_in], 
              message: ->(_, _) { label(:bad_values) }
          } if options[:values_in]

          validations[:format] = {
            with: options[:format], 
            message: ->(_, _) { label(:bad_format) }
          } if options[:format]

          form.validates(name, validations)
        end

        def map_model(form, data)
          form[name] = data[name].strip if data[name].present?
        end

        def sanitized_value(value)
          return value.strip if value.present? && !value.blank?
          nil
        end
        
        def form_tag(form_tag)
          content_tag(
            :div,
            form_tag.text_field(
              name,
              label: label(:label),
              help_text: label_exists?(:help_text) && label(:help_text)
            ),
            class: class_name
          )
        end
      end
    end
  end
end
