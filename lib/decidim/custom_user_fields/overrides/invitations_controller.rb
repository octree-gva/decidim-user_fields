# frozen_string_literal: true

module Decidim
  module CustomUserFields
    module InvitationAcceptExtendedData
      def accept_resource
        custom_params = extract_custom_field_params
        if (validation_errors = validate_custom_params(custom_params)).any?
          return invalid_invitation_resource(validation_errors)
        end

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

        user_params = params[:user].to_unsafe_h.with_indifferent_access if params[:user].respond_to?(:to_unsafe_h)
        user_params ||= params[:user].to_h.with_indifferent_access
        custom_keys = RegistrationFields.all_registration_fields.map { |field| field.name.to_s }
        extracted = user_params.slice(*custom_keys)
        custom_keys.each do |key|
          params[:user].delete(key) if params[:user].respond_to?(:delete)
          params[:user].delete(key.to_sym) if params[:user].respond_to?(:delete)
        end
        extracted
      end

      def validate_custom_params(custom_params)
        organization = invitation_organization
        return ActiveModel::Errors.new(Object.new) if custom_params.blank? || organization.blank?

        ExtendedData.validate_params(organization, custom_params)
      end

      def invalid_invitation_resource(errors)
        resource = resource_class.find_by_invitation_token(invitation_token, true)
        errors.each { |error| resource.errors.add(error.attribute, error.message) }
        assign_invitation_form_with_errors!(resource, errors)
        resource
      end

      def invitation_token
        params.dig(:user, :invitation_token) || params[:invitation_token]
      end

      def invitation_organization
        resource_class.find_by_invitation_token(invitation_token, true)&.organization
      end

      def persist_invitation_extended_data!(resource, custom_params)
        success, errors = ExtendedData.merge_into(resource, resource.organization, custom_params)
        return if success

        errors.each do |error|
          resource.errors.add(error.attribute, error.message)
        end
        assign_invitation_form_with_errors!(resource, errors)
      end

      def assign_invitation_form_with_errors!(resource, errors)
        @form = invitation_registration_form(resource)
        merge_invitation_params_into_form!(@form)
        copy_errors_to_form!(@form, errors)
      end

      def invitation_registration_form(resource)
        Decidim::RegistrationForm.from_model(resource).with_context(
          current_organization: invitation_organization,
          current_user: try(:current_user),
          invitation_token:
        )
      end

      def merge_invitation_params_into_form!(form)
        return unless params[:user]

        user_params = params[:user].to_unsafe_h.with_indifferent_access if params[:user].respond_to?(:to_unsafe_h)
        user_params ||= params[:user].to_h.with_indifferent_access

        user_params.each do |key, value|
          setter = :"#{key}="
          form.public_send(setter, value) if form.respond_to?(setter)
        end
      end

      def copy_errors_to_form!(form, errors)
        errors.each do |error|
          form.errors.add(error.attribute, error.message)
        end
      end
    end
  end
end
