# frozen_string_literal: true

module Decidim
  module CustomUserFields
    module Overrides
      module SettingsFormBuilder
        def collection_for(attribute)
          invoke_collection_method(:"collection_for_#{attribute}")
        end

        def select_collection_for(attribute)
          invoke_collection_method(:"select_for_#{attribute}")
        end

        def invoke_collection_method(method)
          return object.public_send(method) if object.respond_to?(method)

          object.class.respond_to?(method) ? object.class.public_send(method) : nil
        end
      end
    end
  end
end
