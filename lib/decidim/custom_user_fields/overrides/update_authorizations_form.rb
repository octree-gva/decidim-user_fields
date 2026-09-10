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
          pairs_for(selectable_workflows)
        end

        def collection_for_ephemeral_participation_authorization
          return [] unless self.class.ephemeral_mode?

          pairs_for(ephemerable_workflows)
        end

        def selectable_workflows
          Verifications.selectable_workflows(current_organization)
        end

        def ephemerable_workflows
          selectable_workflows.select { |workflow| workflow.respond_to?(:ephemerable) && workflow.ephemerable }
        end

        def pairs_for(workflows)
          workflows.map { |workflow| [workflow.name, workflow.description] }
        end
      end
    end
  end
end
