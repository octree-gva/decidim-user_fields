# frozen_string_literal: true

namespace :decidim_custom_user_fields do
  namespace :dev do
    desc "Register openid_connect as an omniauth provider in the dummy app (local Zitadel testing)"
    task prepare_omniauth: :environment do
      result = Decidim::CustomUserFields::Dev::OmniauthProvidersPatcher.call
      puts "decidim_custom_user_fields:dev:prepare_omniauth — #{result}"
    end

    desc "Seed demo organization with Zitadel OIDC + scenario customizations"
    task seed: :environment do
      Decidim::CustomUserFields::Dev::LocalOidcSeeder.call
    end
  end
end
