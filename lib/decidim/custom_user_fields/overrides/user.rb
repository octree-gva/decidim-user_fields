# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module CustomUserFields
    module UserExtendedDataGuard
      extend ActiveSupport::Concern

      # Make User::exphemeral nil-safe, required after bringing ephemeral users into core (see https://github.com/decidim/decidim/pull/13579)
      def ephemeral?
        (extended_data || {})["ephemeral"]
      end
    end
  end
end
