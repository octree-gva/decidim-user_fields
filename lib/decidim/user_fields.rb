# frozen_string_literal: true

require "decidim/custom_user_fields/fields/generic_field"
require "decidim/custom_user_fields/fields/dummy_field"
require "decidim/custom_user_fields/fields/date_field"
require "decidim/custom_user_fields/fields/text_area_field"
require "decidim/custom_user_fields/fields/text_field"
require "decidim/custom_user_fields/fields/extra_field_ref_field"
require "decidim/custom_user_fields/fields/boolean_field"
require "decidim/custom_user_fields/field_definition"
require "decidim/custom_user_fields/customization_field_naming"
require "decidim/custom_user_fields/extended_data"

require "decidim/custom_user_fields/helpers/application_helper"
require "decidim/custom_user_fields/custom_user_fields"
require "decidim/custom_user_fields/version"
require "decidim/custom_user_fields/customizations"
require "decidim/custom_user_fields/registration_fields"
require "decidim/custom_user_fields/upgrade/migrate_toggle_config"
require "decidim/custom_user_fields/overrides/command"
require "decidim/custom_user_fields/overrides/omniauth_command"
require "decidim/custom_user_fields/overrides/invitations_controller"
require "decidim/custom_user_fields/overrides/form_definition"
require "decidim/custom_user_fields/decidim_integrations"

require "decidim/custom_user_fields/engine"

if defined?(Rails) && (Rails.env.development? || ENV["ZITADEL_OIDC_ENABLED"].present?)
  require "decidim/custom_user_fields/dev/scenario_customizations"
  require "decidim/custom_user_fields/dev/secrets_patcher"
  require "decidim/custom_user_fields/dev/local_oidc_seeder"
  require "decidim/custom_user_fields/dev/openid_connect_setup"
end

require "decidim/custom_user_fields/verifications/builder"
require "decidim/custom_user_fields/verifications/verifications"

Decidim.register_global_engine(
  :decidim_custom_user_fields,
  Decidim::CustomUserFields::Engine,
  at: "/decidim_custom_user_fields"
)
