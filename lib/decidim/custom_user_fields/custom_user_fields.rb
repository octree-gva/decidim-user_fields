# frozen_string_literal: true

module Decidim
  module CustomUserFields
    include ActiveSupport::Configurable

    def self.configure
      yield self
    end

    ##
    # If users should receive emails on notification
    # by default
    # @deprecated < 0.27 only
    config_accessor :default_email_on_notification do
      false
    end

    def self.register_customization(name, &block)
      Customizations.register(name, &block)
    end

    class Error < StandardError; end
  end
end
