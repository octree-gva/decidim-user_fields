# frozen_string_literal: true

module Decidim
  module CustomUserFields
    module Fields
      class ExtraFieldRefField < GenericField
        attr_accessor :reference, :field_set_name

        def configure_form(form)
          self.reference = resolve_reference_definition
          reference.options = reference.options.merge(options) unless options.empty?
          reference.configure_form(form)
        end

        def validate_field_set_reference!
          resolve_reference_definition
        end

        def map_model(_form, _data)
          raise Error, "Can't use Extra Field Ref for registration"
        end

        def form_tag(form)
          user = current_user(form)
          extended_data = user.extended_data.with_indifferent_access
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
          (options[:ref] || name).to_sym
        end

        def resolve_reference_definition
          if field_set_name.blank?
            raise "field_set must be set for extra_field_ref field #{name}"
          end

          field_set = RegistrationFieldSets.find(field_set_name)
          raise "Field set #{field_set_name} not found" unless field_set

          match = field_set.fields.find { |field| field.name == reference_field_name }
          raise "Field #{reference_field_name} not found in field set #{field_set_name}" unless match

          match.deep_dup
        end

        def current_user(form)
          form.object.user
        end
      end
    end
  end
end
