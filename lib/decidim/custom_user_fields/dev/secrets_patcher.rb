# frozen_string_literal: true

require "pathname"

module Decidim
  module CustomUserFields
    module Dev
      # Idempotently adds openid_connect under development.omniauth only.
      # Do not patch the YAML default anchor — test/production inherit it and CI
      # must keep Decidim's stock test omniauth providers.
      class SecretsPatcher
        SNIPPET = <<~YAML
          openid_connect:
            enabled: <%= Decidim::Env.new("OMNIAUTH_OPENID_CONNECT_ENABLED", "true").to_boolean_string %>
            icon: shield-line
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
          patched = strip_root_openid_connect(content)
          status = patched == content ? :skipped : :patched

          unless development_omniauth_has_openid_connect?(patched)
            unless patched.match?(/^(development:\n(?:.*\n)*?  omniauth:\n(?:.*\n)*?    developer:.*?\n\s+icon:.*?\n)/m)
              raise "Could not locate development.omniauth.developer in #{secrets_path}"
            end

            patched = patched.sub(
              /(^development:\n(?:.*\n)*?  omniauth:\n(?:.*\n)*?    developer:.*?\n\s+icon:.*?\n)/m,
              "\\1#{indent_snippet}\n"
            )
            status = :patched
          end

          secrets_path.write(patched) if status == :patched
          status
        end

        private

        attr_reader :secrets_path

        def indent_snippet(spaces = 4)
          prefix = " " * spaces
          SNIPPET.lines.map { |line| line.empty? ? line : "#{prefix}#{line}" }.join.rstrip
        end

        def strip_root_openid_connect(content)
          content.gsub(/^openid_connect:\n(?:  .*\n)*/, "")
        end

        def development_omniauth_has_openid_connect?(content)
          content.match?(/^development:\n(?:.*\n)*?^  omniauth:\n(?:.*\n)*?^    openid_connect:/m)
        end
      end
    end
  end
end
