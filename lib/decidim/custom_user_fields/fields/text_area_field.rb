module Decidim
  module CustomUserFields
    module Fields
      class TextAreaField < GenericField
        def configure_form(form)
          form.attribute(name, String)
          form.validates(name, presence: required?)
          if options[:min].present? || options[:max].present?
            min_max_options = {}
            min_max_options[:minimum] = options[:min].to_i
            min_max_options[:maximum] = options[:max].to_i
            form.validates(name, length: min_max_options, allow_blank: !required?)
          end
        end

        def map_model(form, data)
          form[name] = data[name] if data[name].present?
        end

        def form_tag(form_tag)
          field_options = {
            rows: options[:row] || 2
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
