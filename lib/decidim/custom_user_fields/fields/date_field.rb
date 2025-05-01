# frozen_string_literal: true

module Decidim
  module CustomUserFields
    module Fields
      class DateField < GenericField
        def configure_form(form)
          form.attribute(name, String)
          validations = {
            presence: required? && {
              message: proc do |_object, _data|
                label(:required)
              end
            },
            format: {
              with: /\A\d{4}-\d{2}-\d{2}\z/,
              message: proc do
                label(:bad_format)
              end
            }
          }
          form.validates(name, validations)
        end

        def validate(value, _data, errors)
          date_value = nil
          begin
            date_value = Date.strptime(value, "%Y-%m-%d")
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
          options = {
            label: label(:label),
            help_text: label_exists?(:help_text) && label(:help_text),
            label_options: { class: label_class_name },
            class: class_name
          }
          options[:value] = Date.strptime(form_tag.object[name], "%Y-%m-%d") if form_tag.object[name].present?
          form_tag.date_field(
            name,
            options
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
          errors.add(name, label(:bad_not_before)) if value < not_before_date
        end

        def validate_not_after(value, errors)
          errors.add(name, label(:bad_not_after)) if value > not_after_date
        end
      end
    end
  end
end
