---
sidebar_position: 6
description: How to add a new field type
---
# Add a new field type
This module does not allow to register new field type outside the module (yet). To add a field type, you first need to define a type name (symbole). 
Once choosen, add it to the `lib/decidim/custom_user_fields/field_definition.rb`: 

```ruby
        case type
        when :text
          @field = Fields::TextField.new(self, kwargs)
        when :star # Add a new field here !
          @field = Fields::StarField.new(self, kwargs)
        # ...
```

Once done, you will need to define a new file in `lib/decidim/custom_user_fields/fields` and require it in `lib/decidim/user_fields.rb`.
So, you can create a `lib/decidim/custom_user_fields/fields/star_field.rb`: 

```
# frozen_string_literal: true

module Decidim
  module CustomUserFields
    module Fields
      class StarField < GenericField
        def configure_form(form)
          form.attribute(name, integer)
          validations = {
            presence: required?
          }
          if options[:values_in]
            validations[:inclusion] = {
              in: options[:values_in],
              message: Proc.new do 
                label(:bad_values)
              end
            }
          end

          form.validates(name, validations)
        end

        def map_model(form, data)
          form[name] = data[name] if data[name].present?
        end

        def sanitized_value(value)
          numeric_value = "#{value}".to_i
          return numeric_value if value.present? && options[:values_in].include? numeric_value

          0
        end

        def form_tag(form_tag)
          content_tag(
            :div,
            # a content_tag to describe how your field should be displayed
            , class: class_name
          )
        end
      end
    end
  end
end
```

Once you have saved and included this file in `lib/decidim/user_fields.rb`, you can setup translations: 
```
      star:
        required: "It is required to give a star"
        bad_values: "This value is invalid"
```

Here you go, you can look at other fields for inspirations. Once you are done, you will be able to configure new authorization forms or registration fields with this new field type.