# frozen_string_literal: true

module Decidim
  module CustomUserFields
    module Fields
      class DummyField < GenericField
        def configure_form(form)
          form.attribute(name, String)
          validations = validation_hash

          form.validates(name, validations)
        end

        def validation_hash
          {
          }
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
          {
            name:,
            label: label(:label),
            help_text: label_exists?(:help_text) && label(:help_text),
            class_name:
          }.to_json
        end
      end
    end
  end
end
