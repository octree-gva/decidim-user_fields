# frozen_string_literal: true

module Decidim
  module CustomUserFields
    class ProfileCompletionsController < Decidim::ApplicationController
      before_action :authenticate_user!

      helper_method :missing_fields

      def show
        return redirect_after_completion if missing_fields.none?

        @form = form_from_user
      end

      def update
        success, errors = ExtendedData.merge_into(current_user, current_organization, field_params)
        return render_invalid(errors) unless success

        remaining = remaining_required
        return render_still_incomplete(remaining) if remaining.any?

        flash[:notice] = ::I18n.t("decidim.custom_user_fields.profile_completion.success")
        redirect_after_completion
      end

      private

      def missing_fields
        @missing_fields ||= RegistrationFields.missing_required(current_user)
      end

      def remaining_required
        current_user.reload
        RegistrationFields.missing_required(current_user)
      end

      def render_still_incomplete(fields)
        @form = form_from_params
        fields.each { |field| @form.errors.add(field.name, :blank) }
        @missing_fields = fields
        render :show
      end

      def redirect_after_completion
        path = stored_location_for(current_user)
        path = nil if path.to_s.include?("complete_profile")
        redirect_to path.presence || decidim.root_path
      end

      def form_from_user
        ProfileCompletionForm.from_model(current_user).with_context(form_context)
      end

      def form_from_params
        ProfileCompletionForm.from_params(params).with_context(form_context)
      end

      def form_context
        { current_organization:, current_user: }
      end

      def field_params
        keys = RegistrationFields.active_registration_fields(current_organization).map(&:name)
        params.fetch(:user, {}).permit(*keys).to_h
      end

      def render_invalid(errors)
        @form = form_from_params
        copy_errors_to_form!(errors)
        @missing_fields = RegistrationFields.missing_required(current_user)
        render :show
      end

      def copy_errors_to_form!(errors)
        errors.each { |error| @form.errors.add(error.attribute, error.message) }
      end
    end
  end
end
