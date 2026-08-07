# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "decidim/custom_user_fields/dev/secrets_patcher"

describe Decidim::CustomUserFields::Dev::SecretsPatcher do
  let(:fixture) do
    <<~YAML
      default: &default
        omniauth:
          google_oauth2:
            enabled: false
            client_id:
            client_secret: secret

      development:
        <<: *default
        omniauth:
          developer:
            enabled: true
            icon: phone-line

      test:
        <<: *default
    YAML
  end

  def write_secrets(content)
    path = Pathname.new(Dir.mktmpdir).join("secrets.yml")
    path.write(content)
    path
  end

  it "nests openid_connect under development.omniauth only" do
    path = write_secrets(fixture)

    expect(described_class.call(secrets_path: path)).to eq(:patched)

    content = path.read
    expect(content).to match(/^development:\n(?:.*\n)*?^  omniauth:\n(?:.*\n)*?^    openid_connect:/m)
    default_section = content[/^default: &default\n.*?(?=^development:)/m]
    expect(default_section).not_to include("openid_connect")
    expect(content).not_to match(/^openid_connect:/)
    expect(described_class.call(secrets_path: path)).to eq(:skipped)
  end

  it "heals a root-level openid_connect into development.omniauth" do
    broken = fixture.sub(
      "icon: phone-line\n",
      "icon: phone-line\nopenid_connect:\n  enabled: true\n  icon: shield-line\n"
    )
    path = write_secrets(broken)

    expect(described_class.call(secrets_path: path)).to eq(:patched)

    content = path.read
    expect(content).not_to match(/^openid_connect:/)
    expect(content).to match(/^development:\n(?:.*\n)*?^  omniauth:\n(?:.*\n)*?^    openid_connect:/m)
  end
end
