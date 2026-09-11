# frozen_string_literal: true

require "spec_helper"

describe Decidim::CustomUserFields::AuthorizationsController, :custom_user_fields_scenarios do
  include Devise::Test::IntegrationHelpers

  let(:organization) { create(:organization, available_authorizations: %w(sixteen_plus), favicon: nil) }
  let(:user) { create(:user, :confirmed, organization:) }

  before do
    host! organization.host
    sign_in user
  end

  describe "GET #first_login" do
    it "keeps first login flow when mode is prompt_authorization" do
      Decidim::Toggle.save_config!(
        organization,
        :custom_user_fields,
        { "enabled_customization" => "birthdate_age_gates", "first_login_mode" => "prompt_authorization" },
        merge: false
      )

      get decidim_verifications.first_login_authorizations_path

      expect(response).to redirect_to(
        decidim_verifications.new_authorization_path(handler: "sixteen_plus", redirect_url: decidim.account_path)
      )
    end

    it "redirects away from first login when mode is none" do
      Decidim::Toggle.save_config!(
        organization,
        :custom_user_fields,
        { "enabled_customization" => "birthdate_age_gates", "first_login_mode" => "none" },
        merge: false
      )

      get decidim_verifications.first_login_authorizations_path

      expect(response).to redirect_to(decidim.account_path)
    end
  end
end
