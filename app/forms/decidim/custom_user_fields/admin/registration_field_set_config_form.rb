# frozen_string_literal: true

module Decidim
  module CustomUserFields
    module Admin
      class RegistrationFieldSetConfigForm < Decidim::Form
        include Decidim::Toggle::ModuleConfigForm
        include Decidim::Toggle::InformativeCallouts

        self.module_config_name = "custom_user_fields"

        mimic :organization

        attribute :active_field_set, :string

        validate :active_field_set_is_registered
        validate :no_conflicting_enabled_authorizations

        def self.collection_for_active_field_set
          [["", I18n.t("none", scope: "decidim.custom_user_fields.system.field_sets")]] +
            RegistrationFieldSets.all.map { |set| [set.name.to_s, set.label] }
        end

        def incompatible_authorization_names
          return @incompatible_authorization_names if defined?(@incompatible_authorization_names)

          org = current_organization
          @incompatible_authorization_names = if org
                                                AuthorizationFieldSetCompatibility.incompatible_with_field_set(
                                                  org.available_authorizations,
                                                  active_field_set
                                                )
                                              else
                                                []
                                              end
        end

        private

        def active_field_set_is_registered
          return if active_field_set.blank?
          return if RegistrationFieldSets.find(active_field_set)

          errors.add(:active_field_set, :invalid)
        end

        def no_conflicting_enabled_authorizations
          return if incompatible_authorization_names.blank?

          errors.add(
            :active_field_set,
            I18n.t(
              "incompatible_authorizations",
              scope: "decidim.custom_user_fields.system.field_sets",
              authorizations: incompatible_authorization_names.join(", ")
            )
          )
        end
      end
    end
  end
end
