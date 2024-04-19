module Decidim
    module CustomUserFields
      module Fields
        class DateField < GenericField
          def configure_form(form)
            form.attribute(name, String)
            form.validates(name, presence: required?)
          end
  
          def map_model(form, data)
            form[name] = data[name] if data[name].present?
          end
  
          def form_tag(form_tag)
            field_options = {}
            if options[:min].present? || options[:max].present?
                field_options[:min] = options[:min]
                field_options[:max] = options[:max]
            end

            content_tag(
              :div, 
              form_tag.date_field(name, **field_options), 
              class: class_name
            )
          end
        end
      end
    end
  end
  