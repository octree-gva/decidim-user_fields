# frozen_string_literal: true

# Browsers request /favicon.ico (and sometimes /manifest.webmanifest) when the
# organization has no attached assets. Under Capybara.raise_server_errors (CI),
# those RoutingErrors fail the example. Rails middleware is frozen after boot,
# and appended routes get wiped by reload_routes! — wrap Capybara.app instead.
class BrowserAssetNoopMiddleware
  NOOP_PATHS = %w(/favicon.ico /manifest.webmanifest).freeze

  def initialize(app)
    @app = app
  end

  def call(env)
    return [204, { "Content-Type" => "text/plain" }, []] if NOOP_PATHS.include?(env["PATH_INFO"])

    @app.call(env)
  end
end

RSpec.configure do |config|
  config.before(:suite) do
    next if defined?(@browser_asset_noop_wrapped) && @browser_asset_noop_wrapped

    original = Capybara.app
    Capybara.app = Rack::Builder.new do
      use BrowserAssetNoopMiddleware
      run original
    end
    @browser_asset_noop_wrapped = true
  end
end
