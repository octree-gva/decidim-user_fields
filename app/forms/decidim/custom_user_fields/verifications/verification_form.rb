module Decidim
    module CustomUserFields
        module Verifications
            class VerificationForm < ::Decidim::AuthorizationHandler

                include ActionView::Helpers::SanitizeHelper
                attribute :user, ::Decidim::User
                validate :custom_field_validation
                class << self
                    attr_accessor :decidim_custom_fields
                end


                def fields
                    self.class.decidim_custom_fields
                end

                def custom_field_validation
                    fields.map do |f|                        
                        f.validate(attributes[f.name], attributes, errors)
                    end
                end

                def metadata
                    save_extended_data!
                    hashed = fields.select do |field|
                        !field.skip_hashing?
                    end.map {|f| [f.name, Digest::SHA256.hexdigest(attributes[f.name]) ]}.to_h.to_json
                    data = fields.select do |field|
                        field.skip_hashing?
                    end.map {|f| [f.name, attributes[f.name]]}.to_h
                    super.merge(
                        fields.map do |field|
                            key = field.name
                            plain_val = attributes[key]
                            value = field.skip_hashing? ? plain_val : Digest::SHA256.hexdigest(plain_val)
                            [key, value]
                        end.to_h
                    )
                end
               

                def to_partial_path
                    "/decidim/custom_user_fields/verification_form"
                end

                private

                def extra_fields
                    fields.select {|f| f.type == :extra_field_ref}
                end
                def non_extra_fields
                    fields.select {|f| f.type != :extra_field_ref}
                end
                def save_extended_data!
                    user = attributes["user"]
                    extended_data = user.extended_data.with_indifferent_access
                    extra_fields.select do |field|
                        !field.options[:skip_update_on_verified]
                    end.each do |field|
                        extended_data[field.name] = attributes[field.name]
                    end
                    user.update!(extended_data: extended_data)
                end
                
            end
        end
    end
end
