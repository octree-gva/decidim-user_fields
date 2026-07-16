# frozen_string_literal: true

module Decidim
  module CustomUserFields
    module SpecHelpers
      module SystemCustomizationHelpers
        SCENARIO_AUTHORIZATIONS = {
          birthdate_age_gates: %w(twelve_plus sixteen_plus eighteen_plus),
          location_validation: %w(location_validated),
          association: %w(association_only)
        }.freeze

        def enable_customization_for(organization, *names)
          config = Decidim::Toggle.config_for(organization, :custom_user_fields).dup
          names.each { |name| config[:"#{name}_enabled"] = true }
          Decidim::Toggle.save_config!(organization, :custom_user_fields, config)
        rescue StandardError
          config = names.index_with { true }.transform_keys { |name| :"#{name}_enabled" }
          Decidim::Toggle.save_config!(organization, :custom_user_fields, config)
        end

        def disable_all_customizations_for(organization)
          config = Decidim::CustomUserFields::Customizations.all.to_h do |customization|
            [:"#{customization.name}_enabled", false]
          end
          Decidim::Toggle.save_config!(organization, :custom_user_fields, config)
        end

        def fill_registration_form_base(name: "Nikola Tesla", email: "nikola.tesla@example.org", password: "decidim123456789")
          fill_in :registration_user_name, with: name
          fill_in :registration_user_email, with: email
          fill_in :registration_user_password, with: password
          check :registration_user_tos_agreement
        end

        def complete_registration_newsletter_modal
          return unless page.has_css?("#sign-up-newsletter-modal", visible: :visible, wait: 1)

          click_on "Keep unchecked"
        end

        def submit_registration_form
          within "form.new_user" do
            find("*[type=submit]").click
          end
          complete_registration_newsletter_modal
        end

        def birthdate_for_age(years)
          (years.years.ago + 1.day).to_date.iso8601
        end

        def birthdate_for_age_display(years)
          (years.years.ago + 1.day).to_date.strftime("%d/%m/%Y")
        end

        def birthdate_too_young_for_age(years)
          (years.years.ago + 1.year).to_date.iso8601
        end

        def birthdate_too_young_for_age_display(years)
          (years.years.ago + 1.year).to_date.strftime("%d/%m/%Y")
        end

        def expect_custom_date_field(base_id, label: nil)
          expect(page).to have_field(:"#{base_id}_date")
          expect(page).to have_content(label) if label
        end

        def fill_custom_date_field(base_id, age:)
          fill_in_datepicker :"#{base_id}_date", with: birthdate_for_age_display(age)
        end

        def fill_custom_date_field_iso(base_id, iso_date)
          date = Date.strptime(iso_date, "%Y-%m-%d")
          fill_in_datepicker :"#{base_id}_date", with: date.strftime("%d/%m/%Y")
        end

        def settings_updated_successfully!
          expect(page).to have_content("Settings updated successfully")
        end

        def authorization_workflows_for_specs
          %w(
            dummy_authorization_handler
            twelve_plus
            sixteen_plus
            eighteen_plus
            location_validated
            association_only
          )
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include Decidim::CustomUserFields::SpecHelpers::SystemCustomizationHelpers, type: :system

  config.before(:each, type: :system) do |example|
    next unless example.metadata[:custom_user_fields_scenarios]

    Decidim::CustomUserFields::ScenarioCustomizations.register!

    workflows = example.metadata[:with_authorization_workflows] || authorization_workflows_for_specs
    previous = Decidim::Verifications.workflows.dup
    manifests = workflows.map { |name| Decidim::Verifications.find_workflow_manifest(name) }.compact
    Decidim::Verifications.reset_workflows(*manifests)
    Rails.application.reload_routes!

    example.metadata[:_previous_authorization_workflows] = previous
  end

  config.after(:each, type: :system) do |example|
    previous = example.metadata[:_previous_authorization_workflows]
    next unless previous

    Decidim::Verifications.reset_workflows(*previous)
    Rails.application.reload_routes!
  end
end
