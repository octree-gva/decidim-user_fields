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

          configure_zitadel_http_clients!

          Rails.application.config.middleware.use OmniAuth::Builder do
            provider(
              :openid_connect,
              setup: Decidim::CustomUserFields::Dev::OpenidConnectSetup.provider_setup
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

        # Zitadel resolves the instance from the HTTP Host header (ExternalDomain=localhost).
        # Server-side calls use the Docker service name in the URL but must send Host: localhost:8080.
        def configure_zitadel_http_clients!
          host_header = { "Host" => zitadel_public_host }

          Rack::OAuth2.http_config do |faraday|
            faraday.headers.update(host_header)
          end

          OpenIDConnect.http_config do |faraday|
            faraday.headers.update(host_header)
          end
        end

        def zitadel_public_host
          ENV.fetch("ZITADEL_PUBLIC_HOST") do
            uri = URI.parse(ENV.fetch("OIDC_ISSUER", "http://localhost:8080"))
            uri.port == uri.default_port ? uri.host : "#{uri.host}:#{uri.port}"
          end
        end
      end
    end
  end
end
