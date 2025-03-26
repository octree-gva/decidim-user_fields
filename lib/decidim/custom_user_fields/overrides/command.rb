# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module CustomUserFields
    # Changes in methods to store extra fields in user profile
    module Command
      extend ActiveSupport::Concern

      private

      def create_user
        user_payload = {
          email: form.email,
          name: form.name,
          nickname: form.nickname,
          password: form.password,
          password_updated_at: Time.current,
          organization: form.current_organization,
          tos_agreement: form.tos_agreement,
          newsletter_notifications_at: form.newsletter_at,
          accepted_tos_version: form.current_organization.tos_version,
          locale: form.current_locale,
          extended_data:
        }
        user_payload.email_on_notification = Decidim::CustomUserFields.default_email_on_notification if Decidim.version < "0.27"
        @user = User.create!(user_payload)
      end

      def update_personal_data
        current_user.locale = @form.locale
        current_user.name = @form.name
        current_user.nickname = @form.nickname
        current_user.email = @form.email
        current_user.personal_url = @form.personal_url
        current_user.about = @form.about
        current_user.extended_data = extended_data
      end

      def extended_data
        custom_data = {}
        Decidim::CustomUserFields.custom_fields.each do |field_def|
          custom_data[field_def.name] = @form[field_def.name]
        end
        @extended_data ||= (@user&.extended_data || {}).merge(custom_data)
      end
    end
  end
end
