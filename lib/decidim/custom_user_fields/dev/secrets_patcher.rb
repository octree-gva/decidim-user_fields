# frozen_string_literal: true

require "pathname"

module Decidim
  module CustomUserFields
    module Dev
      # Idempotently adds openid_connect to the dummy app secrets.yml.
      class SecretsPatcher
        SNIPPET = <<~YAML
          openid_connect:
            enabled: <%= Decidim::Env.new("OMNIAUTH_OPENID_CONNECT_ENABLED", "true").to_boolean_string %>
            icon: shield-keyhole-line
        YAML

        def self.call(secrets_path: default_secrets_path)
          new(secrets_path:).call
        end

        def self.default_secrets_path
          module_root = File.expand_path("../../../..", __dir__)
          Pathname.new(module_root).join("spec/decidim_dummy_app/config/secrets.yml")
        end

        def initialize(secrets_path:)
          @secrets_path = Pathname.new(secrets_path)
        end

        def call
          raise "Missing #{secrets_path}. Run: bundle exec rake test_app" unless secrets_path.file?

          content = secrets_path.read
          return :skipped if content.include?("openid_connect:")

          unless content.match?(/\n\s*google_oauth2:\n/)
            raise "Could not locate omniauth section in #{secrets_path}"
          end

          patched = content.sub(
            /(\n\s*google_oauth2:.*?\n\s*client_secret:.*?\n)/m,
            "\\1#{indent_snippet}\n"
          )

          secrets_path.write(patched)
          :patched
        end

        private

        attr_reader :secrets_path

        def indent_snippet
          SNIPPET.lines.map { |line| line.empty? ? line : "    #{line}" }.join.rstrip
        end
      end
    end
  end
end
