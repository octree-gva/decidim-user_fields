# frozen_string_literal: true

module Decidim
  module CustomUserFields
    module Fields
      class ExtraFieldRefField < GenericField
        attr_accessor :reference, :customization_name

        def configure_form(form)
          self.reference = resolve_reference_definition
          reference.configure_form(form)
        end

        def validate_customization_reference!
          resolve_reference_definition
        end

        def validate(value, data, errors)
          resolve_reference_definition.validate(value, data, errors)
        end

        def sanitized_value(raw_value)
          resolve_reference_definition.sanitized_value(raw_value)
        end

        def skip_hashing?
          resolve_reference_definition.skip_hashing?
        end

        def map_model(_form, _data)
          raise Error, "Can't use Extra Field Ref for registration"
        end

        def form_tag(form)
          user = current_user(form)
          extended_data = (user.extended_data || {}).with_indifferent_access
          have_content = reference.map_model(form.object, extended_data)
          if have_content && options[:hide_if_value]
            content_tag(
              :span,
              form.hidden_field(name),
              class: class_name + " #{class_modifer("hidden")}"
            )
          else
            old_context = reference.i18n_context
            reference.i18n_context = i18n_context
            field_tag = reference.form_tag(form)
            reference.i18n_context = old_context
            field_tag
          end
        end

        def i18n_context
          "decidim.custom_user_fields.extended_data"
        end

        private

        def reference_field_name
          CustomizationFieldNaming.prefixed(customization_name, options[:ref] || name)
        end

        def resolve_reference_definition
          if customization_name.blank?
            raise Decidim::CustomUserFields::Error,
                  "customization must be set for extra_field_ref field #{name}"
          end

          customization = Customizations.find(customization_name)
          raise Decidim::CustomUserFields::Error, "Customization #{customization_name} not found" unless customization

          match = customization.fields.find { |field| field.name == reference_field_name }
          unless match
            raise Decidim::CustomUserFields::Error,
                  "Field #{reference_field_name} not found in customization #{customization_name}"
          end

          match.deep_dup.tap do |reference|
            reference.options = reference.options.merge(options) unless options.empty?
          end
        end

        def current_user(form)
          form.object.user
        end
      end
    end
  end
end
