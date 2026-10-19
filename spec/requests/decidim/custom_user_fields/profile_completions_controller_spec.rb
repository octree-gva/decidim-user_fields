# frozen_string_literal: true

require "spec_helper"

describe Decidim::CustomUserFields::ProfileCompletionsController do
  include Devise::Test::IntegrationHelpers

  let(:organization) { create(:organization) }
  let(:user) { create(:user, :confirmed, organization:, extended_data: {}) }
  let(:other_organization) { create(:organization) }

  before do
    host! organization.host
  end

  around do |example|
    with_customizations do
      register_test_customization(:community) do |customization|
        customization.registration_fields do |set|
          set.add_field(:first_name, type: :text, required: true)
          set.add_field(:alias, type: :text, required: false)
        end
      end
      register_test_customization(:other_org) do |customization|
        customization.registration_fields do |set|
          set.add_field(:secret, type: :text, required: true)
        end
      end
      Decidim::CustomUserFields::FormDefinition.setup_form_class(
        Decidim::CustomUserFields::ProfileCompletionForm
      )
      enable_customization_for(organization, :community)
      enable_customization_for(other_organization, :other_org)
      example.run
    end
  end

  describe "GET #show" do
    it "requires sign in" do
      get decidim.account_complete_profile_path

      expect(response).to redirect_to(%r{/users/sign_in})
    end

    it "shows only missing required fields for the current organization" do
      sign_in user

      get decidim.account_complete_profile_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('name="user[community_first_name]"')
      expect(response.body).not_to include('name="user[community_alias]"')
      expect(response.body).not_to include('name="user[other_org_secret]"')
      expect(flash[:alert]).to be_blank
    end

    it "redirects when the profile is already complete" do
      user.update!(extended_data: { "community_first_name" => "Ada" })
      sign_in user

      get decidim.account_complete_profile_path

      expect(response).to redirect_to(decidim.root_path)
    end
  end

  describe "PUT #update" do
    before { sign_in user }

    it "writes extended_data and redirects with a notice" do
      put decidim.account_complete_profile_path, params: {
        user: { community_first_name: "Ada" }
      }

      expect(response).to redirect_to(decidim.root_path)
      expect(flash[:notice]).to eq(I18n.t("decidim.custom_user_fields.profile_completion.success"))
      expect(user.reload.extended_data["community_first_name"]).to eq("Ada")
    end

    it "re-renders with field errors when required values are blank" do
      put decidim.account_complete_profile_path, params: {
        user: { community_first_name: "" }
      }

      expect(response).to have_http_status(:ok)
      expect(flash[:notice]).to be_blank
      expect(response.body).to include('name="user[community_first_name]"')
      expect(user.reload.extended_data["community_first_name"]).to be_blank
    end
  end
end
