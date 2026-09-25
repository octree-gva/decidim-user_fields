# frozen_string_literal: true

require "did_you_mean"

module Decidim
  module CustomUserFields
    # Builds Decidim::CustomUserFields::Error messages for unknown or removed DSL calls.
    module DefinitionGuidance
      LEGACY = {
        custom_fields:
          "Use Customizations.all / register_customization instead of custom_fields.",
        register_field_set:
          "Use register_customization instead of register_field_set.",
        add_field:
          "Use register_customization { registration_fields { |set| set.add_field ... } } " \
          "instead of configure { add_field }."
      }.freeze

      SUPPORTED_FIELD_TYPES = [:dummy, :text, :textarea, :date, :extra_field_ref, :boolean].freeze

      module_function

      def raise_unknown!(receiver, method_name, suggestions: [])
        raise Error, unknown_message(receiver, method_name, suggestions)
      end

      def unknown_message(receiver, method_name, suggestions)
        [
          "#{label(receiver)}##{method_name} is not a valid CustomUserFields DSL call.",
          caller_hint,
          hint_for(receiver, method_name, suggestions)
        ].compact.join(" ")
      end

      def unsupported_type_message(type)
        hint = type_suggestion(type)
        base = "field type #{type} is not supported"
        return "#{base} (supported: #{SUPPORTED_FIELD_TYPES.join(", ")})" if hint.blank?

        "#{base}. Did you mean? #{hint}"
      end

      def hint_for(receiver, method_name, suggestions)
        legacy = legacy_hint(receiver, method_name)
        return legacy if legacy

        match = spell(method_name.to_s, suggestions.map(&:to_s))
        match ? "Did you mean? #{match}" : nil
      end

      def legacy_hint(receiver, method_name)
        key = method_name.to_sym
        return LEGACY[key] if key != :add_field
        return LEGACY[key] if module_receiver?(receiver)

        nil
      end

      def type_suggestion(type)
        spell(type.to_s, SUPPORTED_FIELD_TYPES.map(&:to_s))
      end

      def spell(input, dictionary)
        DidYouMean::SpellChecker.new(dictionary:).correct(input).first
      end

      def module_receiver?(receiver)
        receiver.equal?(Decidim::CustomUserFields)
      end

      def label(receiver)
        receiver.is_a?(Module) ? receiver.name : receiver.class.name
      end

      def caller_hint
        loc = caller_locations.find { |entry| !gem_path?(entry.path) }
        return unless loc

        "(called from #{loc.path}:#{loc.lineno})"
      end

      def gem_path?(path)
        path.include?("custom_user_fields") || path.include?("definition_guidance")
      end
    end

    # Raises DefinitionGuidance errors from method_missing on DSL receivers.
    module DefinitionMissing
      def method_missing(method_name, *_args, &)
        DefinitionGuidance.raise_unknown!(
          self,
          method_name,
          suggestions: dsl_method_names
        )
      end

      def respond_to_missing?(_method_name, _include_private = false)
        false
      end

      def dsl_method_names
        owner = is_a?(Module) ? self : self.class
        return [] unless owner.const_defined?(:DSL_METHODS, false)

        owner::DSL_METHODS
      end
    end
  end
end
