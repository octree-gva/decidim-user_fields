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

        def workflow_field_sets
          @workflow_field_sets ||= {}
        end

        def workflow_field_set(handler_name)
          workflow_field_sets[handler_name.to_s]
        end

        def create_verification_class(class_name)
          # Dynamically create the class within the namespace
          klass = Class.new(Decidim::CustomUserFields::Verifications::VerificationForm)
          const_set(class_name, klass)
          verification_classes.push klass
          klass
        end
      end

      def self.register(verification_name)
        builder = Decidim::CustomUserFields::Verifications::Builder.new(verification_name)
        yield builder
        builder.register_workflow!
        workflow_field_sets[builder.handler_name] = builder.field_set if builder.field_set
      end
    end
  end
end
