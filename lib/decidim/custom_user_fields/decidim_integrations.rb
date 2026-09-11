# frozen_string_literal: true

module Decidim
  module CustomUserFields
    module DecidimIntegrations
      module_function

      def apply!
        include_form(Decidim::RegistrationForm) do |klass|
          next if klass.respond_to?(:require_password_on_accepting)

          klass.define_singleton_method(:require_password_on_accepting) do
            Decidim::User.require_password_on_accepting
          end
        end

        include_form(Decidim::OmniauthRegistrationForm)
        include_form(Decidim::AccountForm)
        prepend_to(Decidim::CreateRegistration, Command)
        prepend_to(Decidim::CreateOmniauthRegistration, OmniauthCommand)
        prepend_to(Decidim::Devise::OmniauthRegistrationsController, OmniauthRegistrationsController)
        prepend_to(Decidim::UpdateAccount, Command)
        prepend_to(Decidim::Devise::InvitationsController, InvitationAcceptExtendedData)
        prepend_to(Decidim::Verifications::AuthorizationsController, AuthorizationsController)
        prepend_to(Decidim::Toggle::UpdateAuthorizationsForm, Overrides::UpdateAuthorizationsForm)
        prepend_to(Decidim::Toggle::UpdateAuthorizationsForm.singleton_class, Overrides::UpdateAuthorizationsForm::ClassMethods)
      end

      def include_form(klass)
        include_module(klass, FormDefinition)
        yield klass if block_given?
      end

      def prepend_to(klass, mod)
        return if klass.included_modules.include?(mod)

        klass.prepend(mod)
      end

      def include_module(klass, mod)
        return if klass.included_modules.include?(mod)

        klass.include(mod)
      end
    end
  end
end
