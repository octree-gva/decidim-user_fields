# frozen_string_literal: true

module Decidim
  module CustomUserFields
    module Verifications
      include ActiveSupport::Configurable

      def self.verifications
        @verifications ||= []
      end

      class << self
        def verification_classes
          @verification_classes ||= []
        end

        def workflow_customizations
          @workflow_customizations ||= {}
        end

        def workflow_customization(handler_name)
          workflow_customizations[handler_name.to_s]
        end

        def workflow_handlers_for(customization_name)
          workflow_customizations.select { |_, name| name.to_s == customization_name.to_s }.keys
        end

        def selectable_workflows(organization)
          enabled = enabled_customization_names(organization)
          Decidim.authorization_workflows.select { |workflow| selectable_workflow?(workflow, enabled) }
        end

        def enabled_customization_names(organization)
          return [] unless organization

          RegistrationFields.enabled_customization_names(organization)
        end

        def selectable_workflow?(workflow, enabled_names)
          customization = workflow_customization(workflow.name)
          customization.blank? || enabled_names.include?(customization.to_s)
        end

        def disabled_handler_names(organization)
          enabled = enabled_customization_names(organization)
          workflow_customizations.filter_map do |handler, name|
            handler.to_s if enabled.exclude?(name.to_s)
          end
        end

        def prune_disabled_handlers(raw, organization)
          prune_raw_authorizations(raw, disabled_handler_names(organization))
        end

        def prune_raw_authorizations(raw, disabled)
          case raw
          when Hash then raw.reject { |name, _| disabled.include?(name.to_s) }
          else Array(raw).map(&:to_s) - disabled
          end
        end

        def create_verification_class(class_name)
          klass = Class.new(Decidim::CustomUserFields::Verifications::VerificationForm)
          const_set(class_name, klass)
          verification_classes.push klass
          klass
        end
      end

      def self.register(verification_name, customization: nil, &)
        builder = Decidim::CustomUserFields::Verifications::Builder.new(verification_name, customization:)
        yield builder
        builder.register_workflow!
        if customization
          workflow_customizations[builder.handler_name] = customization.to_sym
          Customizations.find(customization)&.register_handler!(builder.handler_name)
        end
      end
    end
  end
end
