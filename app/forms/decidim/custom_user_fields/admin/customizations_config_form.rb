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
            super.tap do |form|
              form.enabled_customization = RegistrationFields.enabled_customization_names(organization).first.to_s
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
        end

        private

        def allowed_enabled_customization_values
          Customizations.all.map { |customization| customization.name.to_s }
        end
      end
    end
  end
end
