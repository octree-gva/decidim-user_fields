# frozen_string_literal: true

require "rails"
require "decidim/core"
require "decidim/toggle"
require "deface"

module Decidim
  module CustomUserFields
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::CustomUserFields
      routes do
        # Add engine routes here
        # resources :custom_user_fields
        # root to: "custom_user_fields#index"
      end

      initializer "decidim_custom_user_fields.registration_additions" do
        config.to_prepare do
          Decidim::RegistrationForm.class_eval do
            include CustomUserFields::FormDefinition
            def self.require_password_on_accepting
              Decidim::User.require_password_on_accepting
            end
          end

          Decidim::OmniauthRegistrationForm.class_eval do
            include CustomUserFields::FormDefinition
          end

          Decidim::AccountForm.class_eval do
            include CustomUserFields::FormDefinition
          end

          Decidim::CreateRegistration.class_eval do
            prepend CustomUserFields::Command
          end

          Decidim::UpdateAccount.class_eval do
            prepend CustomUserFields::Command
          end

          Decidim::Toggle::UpdateAuthorizationsForm.include(
            CustomUserFields::Toggle::AuthorizationsFieldSetValidation
          )
        end
      end

      initializer "decidim_custom_user_fields.organization_settings_tab",
                  after: "decidim_toggle.organization_settings_tabs" do
        Decidim::Toggle.settings_tabs :organization_settings do |tabs|
          next unless RegistrationFieldSets.any?

          tabs.add_tab :registration_fields,
                       I18n.t("decidim.custom_user_fields.system.registration_fields_tab"),
                       form: Admin::RegistrationFieldSetConfigForm,
                       command: Decidim::Toggle::UpdateModuleConfigCommand,
                       module_name: :custom_user_fields
        end
      end
    end
  end
end
