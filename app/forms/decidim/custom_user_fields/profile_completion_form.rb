# frozen_string_literal: true

module Decidim
  module CustomUserFields
    class ProfileCompletionForm < Decidim::Form
      mimic :user
    end
  end
end
