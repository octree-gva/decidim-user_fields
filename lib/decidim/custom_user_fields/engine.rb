require 'rails'
require 'decidim/core'
require 'deface'

module Decidim
  module CustomUserFields
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::CustomUserFields
      routes do
        # Add engine routes here
        # resources :custom_user_fields
        # root to: "custom_user_fields#index"
      end

      initializer 'decidim_custom_user_fields.registration_additions' do
        config.to_prepare do
          Decidim::RegistrationForm.class_eval do
            include CustomUserFields::FormsDefinition
            def self.require_password_on_accepting
              Decidim::User.require_password_on_accepting
            end
          end

          Decidim::OmniauthRegistrationForm.class_eval do
            include CustomUserFields::FormsDefinition
          end

          Decidim::AccountForm.class_eval do
            include CustomUserFields::FormsDefinition
          end

          Decidim::CreateRegistration.class_eval do
            prepend CustomUserFields::Command
          end

          Decidim::UpdateAccount.class_eval do
            prepend CustomUserFields::Command
          end
        end
      end
    end
  end
end
