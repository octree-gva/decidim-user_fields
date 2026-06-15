# frozen_string_literal: true

module Decidim
  module CustomUserFields
    module SpecHelpers
      module RegistrationFieldSetHelpers
        def with_registration_field_sets
          Decidim::CustomUserFields::RegistrationFieldSets.clear!
          workflow_field_sets = Decidim::CustomUserFields::Verifications.workflow_field_sets.dup
          Decidim::CustomUserFields::Verifications.workflow_field_sets.clear
          yield
        ensure
          Decidim::CustomUserFields::RegistrationFieldSets.clear!
          Decidim::CustomUserFields::Verifications.workflow_field_sets.clear
          workflow_field_sets&.each do |key, value|
            Decidim::CustomUserFields::Verifications.workflow_field_sets[key] = value
          end
        end

        def register_test_field_set(name = :default, &block)
          Decidim::CustomUserFields.register_field_set(name) do |set|
            block ? yield(set) : set.add_field(:foo, type: :dummy)
          end
        end

        def activate_field_set_for(organization, name)
          Decidim::Toggle.save_config!(organization, :custom_user_fields, { active_field_set: name.to_s })
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include Decidim::CustomUserFields::SpecHelpers::RegistrationFieldSetHelpers
end
