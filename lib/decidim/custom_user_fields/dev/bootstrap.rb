# frozen_string_literal: true

module Decidim
  module CustomUserFields
    module Dev
      # Minimal Decidim org + admin for local OIDC (no full Decidim.seed! demo data).
      class Bootstrap
        ADMIN_EMAIL = "admin@example.org"
        ADMIN_PASSWORD = "decidim123456789"

        def self.call(**options)
          new(**options).call
        end

        def initialize(organization_host: ENV.fetch("DECIDIM_HOST", "localhost"))
          @organization_host = organization_host
        end

        def call
          organization = ensure_organization!
          ensure_terms_of_service!(organization)
          ensure_admin!(organization)
          ensure_system_admin!
          organization
        end

        private

        attr_reader :organization_host

        def ensure_organization!
          Decidim::Organization.find_by(host: organization_host) || Decidim::Organization.create!(
            name: localized("Custom User Fields Dev"),
            host: organization_host,
            secondary_hosts: %w(0.0.0.0 127.0.0.1),
            default_locale: Decidim.default_locale,
            available_locales: Decidim.available_locales,
            reference_prefix: "dev",
            description: localized("Local development organization"),
            smtp_settings: {
              from: "decidim-local <#{ADMIN_EMAIL}>",
              from_email: ADMIN_EMAIL,
              from_label: "decidim-local",
              address: ENV.fetch("SMTP_ADDRESS", "mailcatcher"),
              port: ENV.fetch("SMTP_PORT", "1025"),
              user_name: ENV.fetch("SMTP_USERNAME", ""),
              encrypted_password: Decidim::AttributeEncryptor.encrypt(ENV.fetch("SMTP_PASSWORD", ""))
            },
            colors: { primary: "#bf4044", secondary: "#09780e", tertiary: "#3584e4" },
            available_authorizations: []
          )
        end

        def ensure_terms_of_service!(organization)
          return if Decidim::StaticPage.exists?(organization:, slug: "terms-of-service")

          tos_page = Decidim::StaticPage.create!(
            organization:,
            slug: "terms-of-service",
            title: localized("Terms of service"),
            content: localized("Terms of service for local development."),
            allow_public_access: true
          )
          organization.update!(tos_version: tos_page.updated_at)
        end

        def ensure_admin!(organization)
          user = Decidim::User.find_or_initialize_by(email: ADMIN_EMAIL, organization:)
          user.assign_attributes(
            name: "Admin",
            nickname: "admin",
            password: ADMIN_PASSWORD,
            password_confirmation: ADMIN_PASSWORD,
            confirmed_at: Time.current,
            admin: true,
            admin_terms_accepted_at: Time.current,
            tos_agreement: true,
            accepted_tos_version: organization.tos_version,
            newsletter_notifications_at: Time.current,
            locale: organization.default_locale
          )
          user.save!
          user
        end

        def ensure_system_admin!
          user = Decidim::System::Admin.find_or_initialize_by(email: "system@example.org")
          user.assign_attributes(
            password: "decidim123456789",
            password_confirmation: "decidim123456789",
          )
          user.save!
          user
        end

        def localized(text)
          Decidim.available_locales.index_with { |_locale| text }
        end
      end
    end
  end
end
