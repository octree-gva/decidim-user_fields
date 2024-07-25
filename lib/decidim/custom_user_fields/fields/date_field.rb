module Decidim
  module CustomUserFields
    module Fields
      class DateField < GenericField
        def configure_form(form)
          form.attribute(name, String)
          validations = {
            presence: required? && {
              message: ->() { label(:required) }
            }, 
            format: {
              with: /\A(0[1-9]|[12][0-9]|3[01])\/(0[1-9]|1[0-2])\/\d{4}\z/,
              message: ->() { label(:bad_format) }
            }
          }
          form.validates(name, validations)
        end

        def validate(value, _data, errors)
          date_value = nil
          begin
            date_value = Date.strptime(value, "%d/%m/%Y")
          rescue ::Date::Error
            errors.add(name, label(:bad_date))
            return
          end

          validate_not_before(date_value, errors) if options[:not_before].present?
          validate_not_after(date_value, errors) if options[:not_after].present?
        end

        def map_model(form, data)
          form[name] = data[name] if data[name].present?
        end

        def form_tag(form_tag)
          content_tag(
            :div,
            form_tag.date_field(
              name, 
              label: label(:label),
              help_text: label_exists?(:help_text) && label(:help_text)
            ),
            class: class_name
          )
        end

        private

        def not_before_date
          Date.strptime(options[:not_before], "%Y-%m-%d")
        end
        def not_after_date
          Date.strptime(options[:not_after], "%Y-%m-%d")
        end

        def validate_not_before(value, errors)
          errors.add(name,label(:bad_not_before) ) if value < not_before_date
        end

        def validate_not_after(value, errors)
          errors.add(name,label(:bad_not_after) ) if value > not_after_date
        end
      end
    end
  end
end
