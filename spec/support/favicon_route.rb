# frozen_string_literal: true

# Browsers request /favicon.ico when the organization has no attached favicon.
# Under Capybara.raise_server_errors (CI), that RoutingError fails the example.
RSpec.configure do |config|
  config.before(:suite) do
    Rails.application.routes.append do
      get "/favicon.ico", to: proc { [204, {}, []] }
    end
    Rails.application.reload_routes!
  end
end
