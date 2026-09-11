# frozen_string_literal: true

module Decidim
  module CustomUserFields
    module Overrides
      module UpdateAuthorizationsForm
        module ClassMethods
          def from_model(organization)
            super.with_context(current_organization: organization)
          end
        end

        def collection_for_available_authorizations
          pairs = defined?(super) ? super : self.class.collection_for_available_authorizations
          filter_authorization_pairs(pairs)
        end

        def collection_for_ephemeral_participation_authorization
          pairs = if defined?(super)
                    super
                  elsif self.class.respond_to?(:collection_for_ephemeral_participation_authorization)
                    self.class.collection_for_ephemeral_participation_authorization
                  end
          pairs.blank? ? [] : filter_authorization_pairs(pairs)
        end

        def filter_authorization_pairs(pairs)
          allowed = Verifications.selectable_workflows(current_organization).to_set { |workflow| workflow.name.to_s }
          Array(pairs).select { |name, _label| allowed.include?(name.to_s) }
        end

        def clean_available_authorizations
          cleaned = super
          return cleaned if cleaned.is_a?(Array) || cleaned.is_a?(Hash)
          return wrap_ephemeral_authorizations(Array(cleaned).map(&:to_s)) if persist_authorizations_as_hash?

          Array(cleaned).map(&:to_s).compact_blank
        end

        def persist_authorizations_as_hash?
          Gem.loaded_specs.has_key?("decidim-toggle") && Decidim::Toggle.ephemeral_authorizations_hash?
        end

        def wrap_ephemeral_authorizations(names)
          selected = try(:ephemeral_participation_authorization).to_s
          names.index_with { |name| { "allow_ephemeral_participation" => ephemeral_flag_for(name, selected) } }
        end

        def ephemeral_flag_for(name, selected)
          return name == selected if selected.present?

          previous_ephemeral_handler == name
        end

        def previous_ephemeral_handler
          raw = current_organization&.read_attribute(:available_authorizations)
          return unless raw.is_a?(Hash)

          raw.find { |_name, options| options.is_a?(Hash) && options["allow_ephemeral_participation"] }&.first.to_s
        end
      end
    end
  end
end
