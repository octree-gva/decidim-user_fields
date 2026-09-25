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

        params = omniauth_extended_data
        return if params.blank?

        success, errors = ExtendedData.merge_into(@user, form.current_organization, params)
        return if success

        errors.each { |error| @user.errors.add(error.attribute, error.message) }
        raise ActiveRecord::RecordInvalid, @user
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
