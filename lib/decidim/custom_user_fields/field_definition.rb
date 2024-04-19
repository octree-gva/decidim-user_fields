require 'forwardable'

module Decidim
  module CustomUserFields
    class FieldDefinition
      extend Forwardable

      attr_reader :type,
                  :name,
                  :field

      def_delegators :@field,
                     :configure_form,
                     :map_model,
                     :form_tag

      def initialize(name, kwargs)
        @name = name.to_s.to_sym
        @type = kwargs[:type]
        # TODO: parse kwargs
        case type
        when :text
          @field = Fields::TextField.new(self, kwargs)
        when :textarea
          @field = Fields::TextAreaField.new(self, kwargs)
        when :date
          @field = Fields::DateField.new(self, kwargs)
        else
          raise Error, "field type #{type} is not supported"
        end
      end
    end
  end
end
