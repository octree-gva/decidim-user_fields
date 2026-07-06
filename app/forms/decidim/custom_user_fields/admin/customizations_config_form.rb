# frozen_string_literal: true

module Decidim
  module CustomUserFields
    module Admin
      class CustomizationsConfigForm < Decidim::Form
        include Decidim::Toggle::ModuleConfigForm
        include Decidim::Toggle::InformativeCallouts

        self.module_config_name = "custom_user_fields"

        mimic :organization

        class << self
          def register_toggle_attribute!(customization_name)
            attr = :"#{customization_name}_enabled"
            return if attribute_types.key?(attr.to_s)

            attribute attr, :boolean
          end

          def enabled_customization_names_from(form)
            Customizations.all.filter_map do |customization|
              customization.name.to_s if form.public_send(:"#{customization.name}_enabled")
            end
          end
        end

        validate :no_conflicting_disabled_customizations

        def incompatible_authorization_names
          return @incompatible_authorization_names if defined?(@incompatible_authorization_names)

          org = current_organization
          @incompatible_authorization_names = if org
                                                AuthorizationCustomizationCompatibility.incompatible_with_enabled_customizations(
                                                  org.available_authorizations,
                                                  self.class.enabled_customization_names_from(self)
                                                )
                                              else
                                                []
                                              end
        end

        private

        def no_conflicting_disabled_customizations
          org = current_organization
          return unless org

          Customizations.all.each do |customization|
            next unless customization_being_disabled?(customization.name)

            blocking = AuthorizationCustomizationCompatibility.blocking_authorizations_for_disabled_customization(
              org,
              customization.name
            )
            next if blocking.blank?

            errors.add(
              :"#{customization.name}_enabled",
              I18n.t(
                "incompatible_authorizations",
                scope: "decidim.custom_user_fields.system.customizations",
                authorizations: blocking.join(", ")
              )
            )
          end
        end

        def customization_being_disabled?(name)
          was_enabled = boolean_from_config(previous_config, name)
          now_enabled = public_send(:"#{name}_enabled")
          was_enabled && !now_enabled
        end

        def previous_config
          @previous_config ||= Decidim::Toggle.config_for(current_organization, :custom_user_fields)
        rescue StandardError
          {}
        end

        def boolean_from_config(config, customization_name)
          ActiveModel::Type::Boolean.new.cast(
            config[:"#{customization_name}_enabled"] || config["#{customization_name}_enabled"]
          )
        end
      end
    end
  end
end
