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
          DecidimIntegrations.apply!
        end
      end

      initializer "decidim_custom_user_fields.dev_openid_connect",
                  after: :load_config_initializers do
        next unless defined?(Decidim::CustomUserFields::Dev::OpenidConnectSetup)

        Decidim::CustomUserFields::Dev::OpenidConnectSetup.register_middleware!
      end

      initializer "decidim_custom_user_fields.dev_scenarios" do
        next unless Rails.env.development?

        require "decidim/custom_user_fields/dev/scenario_customizations"
        Rails.application.config.to_prepare do
          Decidim::CustomUserFields::ScenarioCustomizations.register!
        end
      end

      initializer "decidim_custom_user_fields.organization_settings_tab",
                  after: "decidim_toggle.organization_settings_tabs" do
        Decidim::Toggle.settings_tabs :organization_settings do |tabs|
          next unless Customizations.any?

          tabs.add_tab :custom_user_fields,
                       ::I18n.t("decidim.custom_user_fields.system.customizations_tab"),
                       form: Admin::CustomizationsConfigForm,
                       command: UpdateCustomizationsConfigCommand,
                       module_name: :custom_user_fields,
                       form_layout_partial: "decidim/custom_user_fields/system/customizations_tab"
        end
      end
    end
  end
end
