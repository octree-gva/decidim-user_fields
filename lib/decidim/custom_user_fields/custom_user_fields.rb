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

    def self.custom_fields
      @custom_fields ||= []
    end

    def self.add_field(field_type, field_definition)
      custom_fields.push(FieldDefinition.new(field_type, field_definition, "extended_data"))
      self
    end

    class Error < StandardError; end
  end
end
