# frozen_string_literal: true

module Decidim
  module CustomUserFields
    class UpdateCustomizationsConfigCommand < Decidim::Command
      def initialize(organization, form)
        @organization = organization
        @form = form
      end

      def call
        return broadcast(:invalid) if form.class.module_config_name.blank?
        return broadcast(:invalid) if form.invalid?

        persist_and_prune!
        broadcast(:ok)
      rescue ActiveRecord::RecordInvalid
        broadcast(:invalid)
      end

      private

      attr_reader :organization, :form

      def persist_and_prune!
        Decidim::Toggle.save_config!(organization, form.class.module_config_name, form.to_h)
        prune_disabled_authorization_handlers!
      end

      def prune_disabled_authorization_handlers!
        current = organization.read_attribute(:available_authorizations)
        pruned = Verifications.prune_disabled_handlers(current, organization)
        return if pruned == current

        organization.update!(available_authorizations: pruned)
      end
    end
  end
end
