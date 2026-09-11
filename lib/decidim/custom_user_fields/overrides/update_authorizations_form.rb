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
          filter_authorization_pairs(self.class.collection_for_available_authorizations)
        end

        def collection_for_ephemeral_participation_authorization
          return [] unless self.class.respond_to?(:collection_for_ephemeral_participation_authorization)

          filter_authorization_pairs(self.class.collection_for_ephemeral_participation_authorization)
        end

        def filter_authorization_pairs(pairs)
          allowed = Verifications.selectable_workflows(current_organization).to_set { |workflow| workflow.name.to_s }
          Array(pairs).select { |name, _label| allowed.include?(name.to_s) }
        end
      end
    end
  end
end
