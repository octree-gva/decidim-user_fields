# frozen_string_literal: true

module Decidim
  module CustomUserFields
    module AuthorizationsController
      def first_login
        unless RegistrationFields.prompt_authorization_on_first_login?(current_organization)
          redirect_to view_context.cta_button_path
          return
        end

        super
      end
    end
  end
end
