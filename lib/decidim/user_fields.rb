# frozen_string_literal: true

require "decidim/custom_user_fields/fields/generic_field"
require "decidim/custom_user_fields/fields/dummy_field"
require "decidim/custom_user_fields/fields/date_field"
require "decidim/custom_user_fields/fields/text_area_field"
require "decidim/custom_user_fields/fields/text_field"
require "decidim/custom_user_fields/fields/extra_field_ref_field"
require "decidim/custom_user_fields/field_definition"

require "decidim/custom_user_fields/helpers/application_helper"
require "decidim/custom_user_fields/custom_user_fields"
require "decidim/custom_user_fields/registration_field_sets"
require "decidim/custom_user_fields/registration_fields"
require "decidim/custom_user_fields/authorization_field_set_compatibility"
require "decidim/custom_user_fields/toggle/authorizations_field_set_validation"
require "decidim/custom_user_fields/overrides/command"
require "decidim/custom_user_fields/overrides/form_definition"

require "decidim/custom_user_fields/engine"

require "decidim/custom_user_fields/verifications/builder"
require "decidim/custom_user_fields/verifications/verifications"

Decidim.register_global_engine(
  :decidim_custom_user_fields, # this is the name of the global method to access engine routes
  Decidim::CustomUserFields::Engine,
  at: "/decidim_custom_user_fields"
)
