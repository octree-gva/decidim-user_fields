# frozen_string_literal: true

base_path = File.expand_path("..", __dir__)

Decidim::Webpacker.register_path("#{base_path}/app/packs")
Decidim::Webpacker.register_entrypoints(
  decidim_custom_user_fields: "#{base_path}/app/packs/entrypoints/decidim_custom_user_fields.js"
)
Decidim::Webpacker.register_stylesheet_import("stylesheets/decidim/custom_user_fields/decidim_custom_user_fields")
