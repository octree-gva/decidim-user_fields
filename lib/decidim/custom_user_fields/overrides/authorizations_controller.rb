# frozen_string_literal: true

module Decidim
  module CustomUserFields
    module AuthorizationsController
      def onboarding_pending
        unless RegistrationFields.prompt_authorization_on_first_login?(current_organization)
          redirect_to decidim.account_path
          return
        end

        super
      end
    end
  end
end
