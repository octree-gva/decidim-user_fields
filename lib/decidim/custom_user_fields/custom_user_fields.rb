# frozen_string_literal: true

module Decidim
  module CustomUserFields
    include ActiveSupport::Configurable

    def self.configure
      yield self
    end

    def self.register_customization(name, &)
      Customizations.register(name, &)
    end

    class Error < StandardError; end
  end
end
