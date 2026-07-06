# frozen_string_literal: true

namespace :decidim_custom_user_fields do
  namespace :dev do
    desc "Add openid_connect to the dummy app secrets.yml (local Zitadel testing)"
    task prepare_secrets: :environment do
      result = Decidim::CustomUserFields::Dev::SecretsPatcher.call
      puts "decidim_custom_user_fields:dev:prepare_secrets — #{result}"
    end

    desc "Seed demo organization with Zitadel OIDC + scenario customizations"
    task seed: :environment do
      Decidim::CustomUserFields::Dev::LocalOidcSeeder.call
    end
  end
end
