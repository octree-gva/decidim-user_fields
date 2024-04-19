module Decidim
  module CustomUserFields
    module Fields
      class TextField < GenericField
        def configure_form(form)
          form.attribute(name, String)
          form.validates(name, presence: required?)
        end

        def map_model(form, data)
          form[name] = data[name] if data[name].present?
        end

        def form_tag(form_tag)
          content_tag(
            :div, 
            form_tag.text_field(name), 
            class: class_name
          )
        end
      end
    end
  end
end
