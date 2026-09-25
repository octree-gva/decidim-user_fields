# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module CustomUserFields
    module OmniauthRegistrationsController
      extend ActiveSupport::Concern

      private

      def verified_email
        @verified_email ||= begin
          email = oauth_verified_email
          email ||= trusted_form_email_for_openid_connect
          session[:verified_email] = email if email.present?
          email.presence || session[:verified_email]
        end
      end

      def user_params_from_oauth_hash
        return nil if oauth_data.empty?

        uid = resolve_omniauth_uid
        return nil if uid.blank?

        info = oauth_info_with_indifferent_access

        {
          provider: oauth_data[:provider],
          uid:,
          name: info[:name],
          nickname: info[:nickname],
          oauth_signature: OmniauthRegistrationForm.create_signature(oauth_data[:provider], uid),
          avatar_url: info[:image],
          raw_data: oauth_hash
        }
      end

      def oauth_verified_email
        info = oauth_info_with_indifferent_access
        email = info[:email].presence || raw_omniauth_info[:email].presence
        return if email.blank?
        return email if openid_connect_provider?
        return email unless info.has_key?(:email_verified)

        ActiveModel::Type::Boolean.new.cast(info[:email_verified]) ? email : nil
      end

      def trusted_form_email_for_openid_connect
        return unless Rails.env.development?
        return unless openid_connect_registration?

        @form&.email.presence || params.dig(:user, :email).presence
      end

      def openid_connect_registration?
        openid_connect_provider? && oauth_identity_present?
      end

      def openid_connect_provider?
        provider = oauth_data[:provider].presence || params.dig(:user, :provider)
        provider.to_s == "openid_connect"
      end

      def oauth_identity_present?
        resolve_omniauth_uid.present?
      end

      def resolve_omniauth_uid
        uid = oauth_data[:uid]
        return uid.to_s if uid.present?

        raw = raw_omniauth_info
        raw[:sub].presence || raw[:id].presence || raw[:uid].presence || raw[:nickname].presence ||
          oauth_info_with_indifferent_access[:nickname].presence ||
          oauth_info_with_indifferent_access[:email].presence
      end

      def oauth_info_with_indifferent_access
        info = oauth_data[:info] || {}
        info = info.with_indifferent_access if info.respond_to?(:with_indifferent_access)
        info
      end

      def raw_omniauth_info
        raw = oauth_hash.dig(:extra, :raw_info) || {}
        raw = raw.with_indifferent_access if raw.respond_to?(:with_indifferent_access)
        raw
      end
    end
  end
end
