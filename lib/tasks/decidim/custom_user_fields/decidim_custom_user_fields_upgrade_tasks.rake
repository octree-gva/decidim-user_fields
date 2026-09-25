# frozen_string_literal: true

namespace :decidim_custom_user_fields do
  namespace :upgrade do
    desc "Migrate decidim-toggle custom_user_fields config from active_field_set to enabled_customization"
    task migrate_toggle_config: :environment do
      dry_run = ActiveModel::Type::Boolean.new.cast(ENV.fetch("DRY_RUN", nil))
      result = Decidim::CustomUserFields::Upgrade::MigrateToggleConfig.run(dry_run:)
      puts(
        "decidim_custom_user_fields:upgrade:migrate_toggle_config — " \
        "migrated #{result[:migrated]}, skipped #{result[:skipped]}" \
        "#{dry_run ? " (dry run)" : ""}"
      )
    end
  end
end
