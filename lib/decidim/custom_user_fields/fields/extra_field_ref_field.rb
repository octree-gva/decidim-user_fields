# frozen_string_literal: true

module Decidim
  module CustomUserFields
    module Fields
      class ExtraFieldRefField < GenericField
        attr_accessor :reference, :customization_name

        delegate :configure_form, :validate, :sanitized_value, :skip_hashing?, to: :peer_field

        def validate_customization_reference!
          resolve_reference_definition
        end

        def map_model(_form, _data)
          raise Error, "Can't use Extra Field Ref for registration"
        end

        def form_tag(form)
          user = current_user(form)
          extended_data = (user.extended_data || {}).with_indifferent_access
          ref = resolve_reference_definition
          stored = extended_data[ref.name]
          assign_form_value(form.object, stored) if stored.present?

          if stored.present? && options[:hide_if_value]
            content_tag(
              :span,
              form.hidden_field(name),
              class: "#{class_name} #{class_modifer("hidden")}"
            )
          else
            peer = peer_field
            old_context = peer.i18n_context
            peer.i18n_context = i18n_context
            field_tag = peer.form_tag(form)
            peer.i18n_context = old_context
            field_tag
          end
        end

        def i18n_context
          "decidim.custom_user_fields.extended_data"
        end

        private

        def peer_field
          @peer_field ||= build_peer_field
        end

        def build_peer_field
          ref = resolve_reference_definition
          peer_type = ref.type
          if peer_type == :extra_field_ref
            raise Decidim::CustomUserFields::Error,
                  "extra_field_ref #{name} resolved to another extra_field_ref (#{reference_field_name})"
          end

          # Force :type last so neither ref.options nor overlays can recreate ExtraFieldRefField.
          kwargs = ref.options.except(:type, "type", :ref, "ref").merge(overlay_options).merge(type: peer_type)
          FieldDefinition.new(name, kwargs, handler_name).field
        end

        def reference_field_name
          CustomizationFieldNaming.prefixed(customization_name, options[:ref] || name)
        end

        def storage_name
          reference_field_name
        end

        # Extra-field-ref metadata must not leak into the peer field kwargs
        # (especially :type), or FieldDefinition rebuilds another ExtraFieldRefField.
        def overlay_options
          options.except(:ref, :type, :hide_if_value, :skip_update_on_verified, "ref", "type")
        end

        def resolve_reference_definition
          @reference ||= begin
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
              overlays = overlay_options
              next if overlays.empty?

              reference.options = reference.options.except(:type, "type").merge(overlays)
            end
          end
        end

        def assign_form_value(form_object, value)
          if form_object.respond_to?("#{name}=")
            form_object.public_send("#{name}=", value)
          else
            form_object[name] = value
          end
        end

        def current_user(form)
          form.object.user
        end
      end
    end
  end
end
