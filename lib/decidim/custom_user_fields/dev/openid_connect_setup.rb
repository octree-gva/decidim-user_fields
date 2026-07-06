# frozen_string_literal: true

module Decidim
  module CustomUserFields
    module Dev
      # Registers the openid_connect OmniAuth strategy for local Zitadel testing.
      module OpenidConnectSetup
        CONFIG_MAPPING = {
          name: :name,
          response_type: :response_type,
          response_mode: :response_mode,
          discovery: :discovery,
          scope: :scope,
          uid_field: :uid_field,
          issuer: :issuer,
          post_logout_redirect_uri: :post_logout_redirect_uri,
          client_options__port: :client_options__port,
          client_options__scheme: :client_options__scheme,
          client_options__host: :client_options__host,
          client_options__authorization_endpoint: :client_options__authorization_endpoint,
          client_options__token_endpoint: :client_options__token_endpoint,
          client_options__userinfo_endpoint: :client_options__userinfo_endpoint,
          client_options__jwks_uri: :client_options__jwks_uri,
          client_options__end_session_endpoint: :client_options__end_session_endpoint,
          client_options__identifier: :client_options__identifier,
          client_options__secret: :client_options__secret,
          client_options__redirect_uri: :client_options__redirect_uri
        }.freeze

        module_function

        def enabled?
          return false unless defined?(OmniAuth::Strategies::OpenIDConnect)

          ActiveModel::Type::Boolean.new.cast(
            ENV.fetch("ZITADEL_OIDC_ENABLED", Rails.env.development?)
          )
        end

        def register_middleware!
          return unless enabled?

          Rails.application.config.middleware.use OmniAuth::Builder do
            provider(
              :openid_connect,
              setup: provider_setup
            )
          end
        end

        def provider_setup
          lambda do |env|
            request = Rack::Request.new(env)
            organization = Decidim::Organization.find_by(host: request.host)
            provider_config = organization&.enabled_omniauth_providers&.fetch(:openid_connect, {}) || {}

            CONFIG_MAPPING.each do |option_key, config_key|
              value = provider_config[config_key]
              next if value.nil?

              if option_key.to_s.include?("__")
                key_parent, key = option_key.to_s.split("__", 2)
                env["omniauth.strategy"].options[key_parent.to_sym] ||= {}
                env["omniauth.strategy"].options[key_parent.to_sym][key.to_sym] = value
              else
                env["omniauth.strategy"].options[option_key] = value
              end
            end

            env["omniauth.strategy"]
          end
        end
      end
    end
  end
end
