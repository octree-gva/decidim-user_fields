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
