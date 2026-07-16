# frozen_string_literal: true

require "spec_helper"

describe "Custom user fields after OIDC registration", :custom_user_fields_scenarios, type: :system do
  let!(:organization) { create(:organization) }

  let(:omniauth_hash) do
    OmniAuth::AuthHash.new(
      provider: "twitter",
      uid: "custom-fields-uid",
      info: {
        name: "Twitter User",
        nickname: "twitter_custom_fields"
      }
    )
  end

  before do
    enable_customization_for(organization, :association)
    switch_to_host(organization.host)

    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:twitter] = omniauth_hash
    OmniAuth.config.add_camelization "twitter", "Twitter"
    OmniAuth.config.request_validation_phase = ->(_env) {} if OmniAuth.config.respond_to?(:request_validation_phase)

    visit decidim.root_path
    click_on("Create an account", match: :first)
    find(".button--x").click
  end

  after do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:twitter] = nil
    OmniAuth.config.camelizations.delete("twitter")
    OmniAuth.config.mock_auth[:openid_connect] = nil
    OmniAuth.config.camelizations.delete("openid_connect")
  end

  it "asks for missing custom fields on the omniauth completion form" do
    expect(page).to have_content("Please complete your profile")
    expect(page).to have_field("registration_user_association_represent_association")

    fill_in :registration_user_email, with: "twitter.custom@example.org"
    check "registration_user_association_represent_association"
    click_on "Complete profile"

    expect(page).to have_content("confirmation link")
    user = Decidim::User.find_by(email: "twitter.custom@example.org")
    expect(user.extended_data["association_represent_association"]).to be(true)
  end

  context "with a verified OAuth email" do
    let(:omniauth_hash) do
      OmniAuth::AuthHash.new(
        provider: "twitter",
        uid: "verified-email-uid",
        info: {
          name: "Twitter User",
          nickname: "twitter_verified",
          email: "twitter.verified@example.org",
          email_verified: true
        }
      )
    end

    it "signs the user in after completing custom fields" do
      expect(page).to have_content("Please complete your profile")
      expect(page).to have_field("registration_user_association_represent_association")

      check "registration_user_association_represent_association"
      click_on "Complete profile"

      expect(page).to have_css(".main-bar #trigger-dropdown-account")
      expect(page).to have_no_content("confirmation link")

      user = Decidim::User.find_by(email: "twitter.verified@example.org")
      expect(user).to be_confirmed
      expect(user.extended_data["association_represent_association"]).to be(true)
    end
  end
end
