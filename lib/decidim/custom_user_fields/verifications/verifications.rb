module Decidim
    module CustomUserFields
        module Verifications
            include ActiveSupport::Configurable

            def self.verifications
                @verifications ||= []
            end

            class << self
                def verification_classes
                    @verification_klasses ||= []
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
            end
        end
    end
end
