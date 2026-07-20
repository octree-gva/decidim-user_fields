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

        validates :first_login_mode,
                  inclusion: { in: RegistrationFields::FIRST_LOGIN_MODES },
                  allow_blank: true

        class << self
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
              [value, I18n.t(value, scope: "decidim.custom_user_fields.system.first_login_mode")]
            end
          end
        end
      end
    end
  end
end
