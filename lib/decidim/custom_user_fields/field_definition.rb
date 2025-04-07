# frozen_string_literal: true

require "forwardable"

module Decidim
  module CustomUserFields
    class FieldDefinition
      extend Forwardable

      attr_reader :type,
                  :name,
                  :field,
                  :handler_name

      def_delegators :@field,
                     :configure_form,
                     :map_model,
                     :form_tag,
                     :options,
                     :options=,
                     :i18n_context,
                     :i18n_context=,
                     :validate,
                     :skip_hashing?,
                     :sanitized_value

      def initialize(name, kwargs, handler_name)
        @handler_name = handler_name
        @name = name.to_s.to_sym
        @type = kwargs[:type]
        case type
        when :dummy
          @field = Fields::DummyField.new(self, kwargs)
        when :text
          @field = Fields::TextField.new(self, kwargs)
        when :textarea
          @field = Fields::TextAreaField.new(self, kwargs)
        when :date
          @field = Fields::DateField.new(self, kwargs)
        when :extra_field_ref
          @field = Fields::ExtraFieldRefField.new(self, kwargs)
        else
          raise Error, "field type #{type} is not supported"
        end
      end
    end
  end
end
