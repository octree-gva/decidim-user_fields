# frozen_string_literal: true

require "decidim/custom_user_fields/definition_guidance"

module Decidim
  module CustomUserFields
    include ActiveSupport::Configurable

    DSL_METHODS = [:configure, :register_customization].freeze

    def self.configure
      yield self
    end

    def self.register_customization(name, &)
      Customizations.register(name, &)
    end

    class Error < StandardError; end

    extend DefinitionMissing
  end
end
