# frozen_string_literal: true

require "pathname"

module Decidim
  module CustomUserFields
    module Dev
      # Idempotently writes the dummy app initializer that registers the
      # openid_connect OmniAuth provider in Decidim.omniauth_providers.
      class OmniauthProvidersPatcher
        SNIPPET = <<~RUBY
          # frozen_string_literal: true

          # Local Zitadel OIDC testing: register the openid_connect provider
          # catalogue entry. Enabled in development only, honouring
          # OMNIAUTH_OPENID_CONNECT_ENABLED; credentials come from the
          # organization record (see Dev::OpenidConnectSetup.provider_setup).
          if Rails.env.development?
            Decidim.omniauth_providers[:openid_connect] = {
              enabled: Decidim::Env.new("OMNIAUTH_OPENID_CONNECT_ENABLED", "true").present?,
              icon: "shield-line"
            }
          end
        RUBY

        def self.call(initializer_path: default_initializer_path)
          new(initializer_path:).call
        end

        def self.default_initializer_path
          module_root = File.expand_path("../../../..", __dir__)
          Pathname.new(module_root).join(
            "spec/decidim_dummy_app/config/initializers/decidim_openid_connect.rb"
          )
        end

        def initialize(initializer_path:)
          @initializer_path = Pathname.new(initializer_path)
        end

        def call
          raise_missing_dummy_app unless dummy_app_installed?

          content = initializer_path.file? ? initializer_path.read : nil
          status = content == SNIPPET ? :skipped : :patched
          initializer_path.write(SNIPPET) if status == :patched
          status
        end

        private

        attr_reader :initializer_path

        def dummy_app_installed?
          dummy_app_root.join("config/application.rb").file?
        end

        def dummy_app_root
          initializer_path.dirname.dirname.dirname
        end

        def raise_missing_dummy_app
          raise "Missing dummy app (#{dummy_app_root}). Run: bundle exec rake test_app"
        end
      end
    end
  end
end
