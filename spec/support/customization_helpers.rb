# frozen_string_literal: true

module Decidim
  module CustomUserFields
    module SpecHelpers
      module CustomizationHelpers
        def with_customizations
          Decidim::CustomUserFields::Customizations.clear!
          workflow_customizations = Decidim::CustomUserFields::Verifications.workflow_customizations.dup
          Decidim::CustomUserFields::Verifications.workflow_customizations.clear
          yield
        ensure
          Decidim::CustomUserFields::Customizations.clear!
          Decidim::CustomUserFields::Verifications.workflow_customizations.clear
          workflow_customizations&.each do |key, value|
            Decidim::CustomUserFields::Verifications.workflow_customizations[key] = value
          end
          Decidim::CustomUserFields::ScenarioCustomizations.register!
        end

        def register_test_customization(name = :default, &block)
          Decidim::CustomUserFields.register_customization(name) do |customization|
            if block
              yield(customization)
            else
              customization.registration_fields do |set|
                set.add_field(:foo, type: :dummy)
              end
            end
          end
        end

        def enable_customization_for(organization, *names)
          config = names.index_with { true }.transform_keys { |name| :"#{name}_enabled" }
          Decidim::Toggle.save_config!(organization, :custom_user_fields, config, merge: false)
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include Decidim::CustomUserFields::SpecHelpers::CustomizationHelpers
end
