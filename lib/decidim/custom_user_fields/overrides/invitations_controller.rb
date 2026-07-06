# frozen_string_literal: true

module Decidim
  module CustomUserFields
    module InvitationAcceptExtendedData
      def accept_resource
        custom_params = extract_custom_field_params
        resource = super
        return resource unless resource.valid? && resource.invitation_accepted?

        persist_invitation_extended_data!(resource, custom_params)
        resource
      end

      protected

      def configure_permitted_parameters
        devise_parameter_sanitizer.permit(
          :accept_invitation,
          keys: [:nickname, :password, :password_confirmation, :tos_agreement, :newsletter_notifications]
        )
      end

      private

      def extract_custom_field_params
        return {} unless params[:user]

        custom_keys = RegistrationFields.all_registration_fields.map { |field| field.name.to_s }
        params[:user].slice(*custom_keys).tap do
          custom_keys.each { |key| params[:user].delete(key) }
        end
      end

      def persist_invitation_extended_data!(resource, custom_params)
        extended_data = (resource.extended_data || {}).with_indifferent_access
        RegistrationFields.active_registration_fields(resource.organization).each do |field_def|
          key = field_def.name
          next unless custom_params.key?(key.to_s)

          extended_data[key] = field_def.sanitized_value(custom_params[key.to_s])
        end
        resource.update!(extended_data:)
      end
    end
  end
end
