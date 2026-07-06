# frozen_string_literal: true

module Decidim
  module CustomUserFields
    module Fields
      class BooleanField < GenericField
        def configure_form(form)
          form.attribute(name, :boolean)
          validations = {}
          if options[:must_be_true]
            validations[:inclusion] = {
              in: [true, "1", 1, "true"],
              message: proc { label(:required) }
            }
          elsif required?
            validations[:inclusion] = {
              in: [true, "1", 1, "true"],
              message: proc { label(:required) }
            }
          end
          apply_form_validations(form, validations)
        end

        def skip_hashing?
          true
        end

        def validate(value, _data, errors)
          return unless options[:must_be_true] || required?

          errors.add(name, label(:required)) unless ActiveModel::Type::Boolean.new.cast(value)
        end

        def map_model(form, data)
          return if data[name].nil?

          form[name] = ActiveModel::Type::Boolean.new.cast(data[name])
        end

        def sanitized_value(value)
          ActiveModel::Type::Boolean.new.cast(value)
        end

        def form_tag(form_tag)
          form_tag.check_box(
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
