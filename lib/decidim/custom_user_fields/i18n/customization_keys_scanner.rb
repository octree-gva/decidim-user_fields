# frozen_string_literal: true

require "i18n/tasks"
require "i18n/tasks/scanners/scanner"
require "i18n/tasks/scanners/results/key_occurrences"
require "i18n/tasks/scanners/results/occurrence"
require "decidim/custom_user_fields/i18n/customization_keys"

module Decidim
  module CustomUserFields
    module I18n
      # Reports {CustomizationKeys.required_keys} as used for i18n-tasks.
      class CustomizationKeysScanner < ::I18n::Tasks::Scanners::Scanner
        def initialize(config: {}, **_kwargs)
          super()
          @config = config
          @registry_ready = false
        end

        def keys
          ensure_registry_loaded!
          return [] unless @registry_ready

          CustomizationKeys.required_keys.map do |key|
            ::I18n::Tasks::Scanners::Results::KeyOccurrences.new(
              key: key,
              occurrences: [synthetic_occurrence(key)]
            )
          end
        end

        private

        attr_reader :config

        def ensure_registry_loaded!
          if defined?(::Rails) && ::Rails.application &&
             defined?(Decidim::CustomUserFields::Customizations)
            @registry_ready = true
            return
          end

          gem_root = ENV.fetch("ENGINE_ROOT") do
            File.expand_path("../../../..", __dir__)
          end
          environment = File.join(gem_root, "spec/decidim_dummy_app/config/environment.rb")
          unless File.exist?(environment)
            warn(
              "[decidim-user_fields] CustomizationKeysScanner: could not load " \
              "#{environment}; registry keys skipped."
            )
            @registry_ready = false
            return
          end

          require environment
          if defined?(Decidim::CustomUserFields::ScenarioCustomizations)
            Decidim::CustomUserFields::ScenarioCustomizations.register!
          end
          @registry_ready = defined?(Decidim::CustomUserFields::Customizations)
        rescue LoadError, StandardError => e
          warn(
            "[decidim-user_fields] CustomizationKeysScanner: failed to boot Rails " \
            "(#{e.class}: #{e.message}); registry keys skipped."
          )
          @registry_ready = false
        end

        def synthetic_occurrence(key)
          ::I18n::Tasks::Scanners::Results::Occurrence.new(
            path: "lib/decidim/custom_user_fields/i18n/customization_keys.rb",
            pos: 0,
            line_num: 1,
            line_pos: 1,
            line: "# registry:#{key}",
            raw_key: key
          )
        end
      end
    end
  end
end
