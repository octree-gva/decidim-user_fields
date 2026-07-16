# frozen_string_literal: true

require "pathname"

module Decidim
  module CustomUserFields
    module Dev
      # Configures the demo organization for local OIDC + scenario customizations.
      class LocalOidcSeeder
        DEFAULT_CUSTOMIZATION = :association

        def self.call(**options)
          new(**options).call
        end

        def initialize(
          oidc_env_path: default_oidc_env_path,
          customization: ENV.fetch("DEV_CUSTOMIZATION", DEFAULT_CUSTOMIZATION).to_sym,
          organization_host: ENV.fetch("DECIDIM_HOST", "localhost")
        )
          @oidc_env_path = Pathname.new(oidc_env_path)
          @customization = customization
          @organization_host = organization_host
        end

        def call
          register_scenarios!
          organization = ensure_organization!
          apply_oidc_settings!(organization)
          enable_customization!(organization)
          enable_authorizations!(organization)
          print_summary(organization)
          organization
        end

        private

        attr_reader :oidc_env_path, :customization, :organization_host

        def default_oidc_env_path
          module_root = File.expand_path("../../../..", __dir__)
          Pathname.new(module_root).join("docker/zitadel/oidc.env")
        end

        def register_scenarios!
          return unless defined?(Decidim::CustomUserFields::ScenarioCustomizations)

          Decidim::CustomUserFields::ScenarioCustomizations.register!
        end

        def ensure_organization!
          Decidim::Organization.find_by(host: organization_host) || Bootstrap.call(organization_host:)
        end

        def apply_oidc_settings!(organization)
          env = load_oidc_env
          settings = organization.omniauth_settings || {}
          public_issuer = env.fetch("OIDC_ISSUER")
          internal_issuer = env.fetch("OIDC_ISSUER_INTERNAL", public_issuer)
          redirect_uri = env.fetch("OIDC_REDIRECT_URI")
          client_id = env.fetch("OIDC_CLIENT_ID")
          client_secret = env.fetch("OIDC_CLIENT_SECRET")
          internal_uri = URI.parse(internal_issuer)
          public_uri = URI.parse(public_issuer)

          settings.merge!(
            "omniauth_settings_openid_connect_enabled" => true,
            "omniauth_settings_openid_connect_name" => "Zitadel",
            "omniauth_settings_openid_connect_scope" => "openid email profile",
            "omniauth_settings_openid_connect_issuer" => public_issuer,
            "omniauth_settings_openid_connect_uid_field" => "sub",
            "omniauth_settings_openid_connect_response_type" => "code",
            "omniauth_settings_openid_connect_discovery" => false,
            "omniauth_settings_openid_connect_icon" => "phone-line",
            "omniauth_settings_openid_connect_client_options__host" => public_uri.host,
            "omniauth_settings_openid_connect_client_options__port" => public_uri.port.to_s,
            "omniauth_settings_openid_connect_client_options__scheme" => public_uri.scheme,
            "omniauth_settings_openid_connect_client_options__identifier" => client_id,
            "omniauth_settings_openid_connect_client_options__secret" => client_secret,
            "omniauth_settings_openid_connect_client_options__redirect_uri" => redirect_uri,
            "omniauth_settings_openid_connect_client_options__authorization_endpoint" =>
              "#{public_issuer}/oauth/v2/authorize",
            "omniauth_settings_openid_connect_client_options__token_endpoint" =>
              "#{internal_issuer}/oauth/v2/token",
            "omniauth_settings_openid_connect_client_options__userinfo_endpoint" =>
              "#{internal_issuer}/oidc/v1/userinfo",
            "omniauth_settings_openid_connect_client_options__jwks_uri" =>
              "#{internal_issuer}/oauth/v2/keys",
            "omniauth_settings_openid_connect_client_options__end_session_endpoint" =>
              "#{public_issuer}/oidc/v1/end_session"
          )

          organization.update!(omniauth_settings: encrypt_omniauth_settings(settings))
        end

        def encrypt_omniauth_settings(settings)
          settings.transform_values do |value|
            Decidim::OmniauthProvider.value_defined?(value) ? Decidim::AttributeEncryptor.encrypt(value) : value
          end
        end

        def enable_customization!(organization)
          Decidim::Toggle.save_config!(
            organization,
            :custom_user_fields,
            { "#{customization}_enabled" => true },
            merge: false
          )
        end

        def enable_authorizations!(organization)
          handlers = Decidim::CustomUserFields::Verifications.workflow_handlers_for(customization)
          return if handlers.empty?

          current = Array(organization.available_authorizations)
          organization.update!(
            available_authorizations: (current + handlers).uniq
          )
        end

        def load_oidc_env
          raise "Missing #{oidc_env_path}. Run: ./bin/dev-oidc-up" unless oidc_env_path.file?

          oidc_env_path.each_line.with_object({}) do |line, env|
            next if line.strip.empty? || line.start_with?("#")

            key, value = line.split("=", 2)
            env[key] = value.to_s.strip
          end.tap do |env|
            %w[OIDC_ISSUER OIDC_REDIRECT_URI OIDC_CLIENT_ID OIDC_CLIENT_SECRET].each do |key|
              raise "Missing #{key} in #{oidc_env_path}" if env[key].blank?
            end
          end
        end

        def print_summary(organization)
          puts <<~MSG

            decidim_custom_user_fields:dev:seed complete
              Organization: #{organization.name} (#{organization.host})
              Customization: #{customization} enabled
              OIDC provider: Zitadel (openid_connect)
              Login: http://localhost:3000/users/sign_in

          MSG
        end
      end
    end
  end
end
