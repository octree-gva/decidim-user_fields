# frozen_string_literal: true

module Decidim
  module CustomUserFields
    module CustomizationFieldNaming
      module_function

      def prefixed(customization_name, field_name)
        name = field_name.to_s
        prefix = "#{customization_name}_"
        return field_name.to_sym if name.start_with?(prefix)

        "#{prefix}#{name}".to_sym
      end
    end
  end
end
