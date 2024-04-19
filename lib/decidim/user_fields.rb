require 'decidim/custom_user_fields/fields/generic_field'
require 'decidim/custom_user_fields/fields/date_field'
require 'decidim/custom_user_fields/fields/text_area_field'
require 'decidim/custom_user_fields/fields/text_field'
require 'decidim/custom_user_fields/field_definition'

require 'decidim/custom_user_fields/helpers/application_helper'
require 'decidim/custom_user_fields/custom_user_fields'
require 'decidim/custom_user_fields/overrides/command'
require 'decidim/custom_user_fields/overrides/form_definition'

require 'decidim/custom_user_fields/engine'

Decidim.register_global_engine(
  :decidim_custom_user_fields, # this is the name of the global method to access engine routes
  ::Decidim::CustomUserFields::Engine,
  at: '/decidim_custom_user_fields'
)
