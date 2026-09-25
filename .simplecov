# frozen_string_literal: true

if ENV["SIMPLECOV"]
  SimpleCov.start do
    minimum_coverage 90
    track_files "**/*.rb"

    # We ignore some of the files because they are never tested
    add_filter "/config/"
    add_filter "/db/"
    add_filter "/vendor/"
    add_filter "/spec/"
    add_filter "/lib/tasks/"
    # Local OIDC / bootstrap helpers — development-only, not product surface
    add_filter "/lib/decidim/custom_user_fields/dev/"
    # i18n rake helpers (invoked via bin/rails i18n:*, not the runtime app)
    add_filter "/lib/decidim/custom_user_fields/i18n/customization_keys_scanner.rb"
    add_filter "/lib/decidim/custom_user_fields/i18n/tasks.rb"
    add_filter "/lib/decidim/custom_user_fields/version.rb"
    add_filter %r{^/decidim-[^/]*/lib/decidim/[^/]*/engine.rb}
    add_filter %r{^/decidim-[^/]*/lib/decidim/[^/]*/admin-engine.rb}
    add_filter %r{^/decidim-[^/]*/lib/decidim/[^/]*/component.rb}
    add_filter %r{^/decidim-[^/]*/lib/decidim/[^/]*/participatory_space.rb}
  end

  SimpleCov.merge_timeout 1800

  if ENV["CI"]
    require "simplecov-cobertura"
    SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter
  end
end
