# frozen_string_literal: true

# Host apps: add to config/i18n-tasks.yml —
#   <% require "decidim/custom_user_fields/i18n/tasks" %>
require "decidim/custom_user_fields/i18n/customization_keys_scanner"

I18n::Tasks.add_scanner "Decidim::CustomUserFields::I18n::CustomizationKeysScanner"
