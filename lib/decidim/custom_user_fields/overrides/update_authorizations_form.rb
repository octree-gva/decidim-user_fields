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
          pairs = defined?(super) ? super : self.class.collection_for_ephemeral_participation_authorization
          filter_authorization_pairs(pairs)
        end

        def filter_authorization_pairs(pairs)
          allowed = Verifications.selectable_workflows(current_organization).to_set { |workflow| workflow.name.to_s }
          Array(pairs).select { |name, _label| allowed.include?(name.to_s) }
        end
      end
    end
  end
end
