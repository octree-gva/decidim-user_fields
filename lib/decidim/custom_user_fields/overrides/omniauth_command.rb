# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module CustomUserFields
    module OmniauthCommand
      extend ActiveSupport::Concern

      private

      def create_or_find_user
        super
        persist_omniauth_extended_data!
      end

      def persist_omniauth_extended_data!
        return unless @user

        data = omniauth_extended_data
        return if data.blank?

        @user.update!(extended_data: (@user.extended_data || {}).merge(data))
      end

      def omniauth_extended_data
        org = form.try(:current_organization)
        custom_data = {}
        RegistrationFields.active_registration_fields(org).each do |field_def|
          custom_data[field_def.name] = form[field_def.name]
        end
        custom_data
      end
    end
  end
end
