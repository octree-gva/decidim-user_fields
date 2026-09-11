# frozen_string_literal: true

module Decidim
  module CustomUserFields
    module Admin
      class CustomizationsConfigForm < Decidim::Form
        include Decidim::Toggle::ModuleConfigForm
        include Decidim::Toggle::InformativeCallouts

        self.module_config_name = "custom_user_fields"

        mimic :organization

        attribute :first_login_mode, :string, default: "prompt_authorization"
        attribute :enabled_customization, :string, default: ""

        validates :first_login_mode,
                  inclusion: { in: RegistrationFields::FIRST_LOGIN_MODES },
                  allow_blank: true
        validates :enabled_customization,
                  inclusion: { in: :allowed_enabled_customization_values },
                  allow_blank: true

        class << self
          def from_model(organization)
            super.tap(&:assign_enabled_customization_from_flags)
          end

          def register_toggle_attribute!(customization_name)
            attr = :"#{customization_name}_enabled"
            return if attribute_types.has_key?(attr.to_s)

            attribute attr, :boolean
          end

          def enabled_customization_names_from(form)
            Customizations.all.filter_map do |customization|
              customization.name.to_s if form.public_send(:"#{customization.name}_enabled")
            end
          end

          def collection_for_first_login_mode
            RegistrationFields::FIRST_LOGIN_MODES.map do |value|
              [value, ::I18n.t(value, scope: "decidim.custom_user_fields.system.first_login_mode")]
            end
          end

          def collection_for_enabled_customization
            [none_customization_option] + customization_radio_options
          end

          def none_customization_option
            ["", ::I18n.t("none", scope: "decidim_toggle.system.custom_user_fields")]
          end

          def customization_radio_options
            Customizations.all.map do |customization|
              name = customization.name.to_s
              [name, ::I18n.t("#{name}_enabled", scope: "decidim_toggle.system.custom_user_fields")]
            end
          end

          def visible_toggle_attribute_names
            attribute_types.keys.map(&:to_sym).reject do |name|
              name == :id || name == :first_login_mode || name.to_s.end_with?("_enabled")
            end
          end
        end

        def assign_enabled_customization_from_flags
          self.enabled_customization = self.class.enabled_customization_names_from(self).first.to_s
        end

        def to_h
          apply_exclusive_enabled_flags
          super.except("enabled_customization", :enabled_customization)
        end

        private

        def apply_exclusive_enabled_flags
          selected = exclusive_enabled_name
          Customizations.all.each do |customization|
            public_send(:"#{customization.name}_enabled=", customization.name.to_s == selected)
          end
        end

        def exclusive_enabled_name
          enabled_customization.to_s.presence || self.class.enabled_customization_names_from(self).first.to_s
        end

        def allowed_enabled_customization_values
          Customizations.all.map { |customization| customization.name.to_s }
        end
      end
    end
  end
end
