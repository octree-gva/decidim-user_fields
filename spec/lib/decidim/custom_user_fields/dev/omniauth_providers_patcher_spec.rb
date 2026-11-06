# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "decidim/custom_user_fields/dev/omniauth_providers_patcher"

describe Decidim::CustomUserFields::Dev::OmniauthProvidersPatcher do
  let(:initializer_name) { "decidim_openid_connect.rb" }

  let(:initializer_path) do
    Pathname.new(dummy_app_root).join("config/initializers").join(initializer_name)
  end

  let(:dummy_app_root) { File.join(tmp_root, "spec/decidim_dummy_app") }

  let(:tmp_root) { Pathname.new(Dir.mktmpdir) }

  before do
    FileUtils.mkdir_p(File.join(dummy_app_root, "config/initializers"))
    FileUtils.touch(File.join(dummy_app_root, "config/application.rb"))
  end

  it "creates the initializer registering the provider under development only" do
    expect(described_class.call(initializer_path:)).to eq(:patched)

    content = initializer_path.read
    expect(content).to include("Decidim.omniauth_providers[:openid_connect]")
    expect(content).to include('if Rails.env.development?')
    expect(content).to include("OMNIAUTH_OPENID_CONNECT_ENABLED")
  end

  it "raises when the dummy app is missing" do
    missing = File.join(tmp_root, "spec/other_app", "config")

    expect do
      described_class.call(initializer_path: Pathname.new(missing).join("initializers", initializer_name))
    end.to raise_error(/bundle exec rake test_app/)
  end

  context "when the initializer already exists" do
    it "skips when the content matches" do
      described_class.call(initializer_path:)

      expect(described_class.call(initializer_path:)).to eq(:skipped)
    end

    it "heals content that drifted from the snippet" do
      initializer_path.write("Decidim.omniauth_providers[:openid_connect] = nil\n")

      expect(described_class.call(initializer_path:)).to eq(:patched)
      expect(initializer_path.read).to include("Decidim.omniauth_providers[:openid_connect]")
      expect(initializer_path.read).not_to include("= nil")
    end
  end

  context "when called with default path" do
    it "points at the dummy app initializer" do
      expect(described_class.default_initializer_path.to_s)
        .to match(%r{spec/decidim_dummy_app/config/initializers/decidim_openid_connect\.rb$})
    end
  end
end
