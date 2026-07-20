# frozen_string_literal: true

require "spec_helper"

describe "System organization customizations toggle", :custom_user_fields_scenarios do
  let(:admin) { create(:admin) }
  let!(:organization) { create(:organization, available_authorizations: [], omniauth_settings: nil) }

  before do
    # System layout renders the public login modal. Keep providers empty so OIDC
    # (compose env / leftover tenant settings) cannot render missing authorize routes.
    allow(Decidim::OmniauthProvider).to receive(:enabled).and_return({})
    Decidim::Organization.find_each { |org| org.update!(omniauth_settings: nil) }
    switch_to_default_host
    login_as admin, scope: :admin
    visit decidim_system.edit_organization_path(organization)
  end

  def within_customizations_tab(&)
    click_on "User fields"
    within("#panel-toggle-custom_user_fields", &)
  end

  def within_authorizations_tab(&)
    click_on "Authorizations"
    within("#panel-toggle-authorizations", &)
  end

  it "enables a customization and exposes its authorizations in the authorizations tab" do
    within_customizations_tab do
      check "organization_birthdate_age_gates_enabled"
      click_on "Save"
    end

    settings_updated_successfully!

    within_authorizations_tab do
      expect(page).to have_content("12 plus")
      expect(page).to have_content("16 plus")
      expect(page).to have_content("18 plus")

      check "organization_available_authorizations_sixteen_plus"
      click_on "Save"
    end

    settings_updated_successfully!
    expect(organization.reload.available_authorizations).to include("sixteen_plus")
  end

  it "allows disabling a customization even when its authorizations remain enabled" do
    enable_customization_for(organization, :birthdate_age_gates)
    organization.update!(available_authorizations: %w(sixteen_plus))

    visit decidim_system.edit_organization_path(organization)
    within_customizations_tab do
      uncheck "organization_birthdate_age_gates_enabled"
      click_on "Save"
    end

    settings_updated_successfully!
    expect(organization.reload.available_authorizations).to include("sixteen_plus")
  end

  it "keeps external authorizations available alongside customization workflows" do
    within_authorizations_tab do
      expect(page).to have_content("Example authorization")
    end

    within_customizations_tab do
      check "organization_association_enabled"
      click_on "Save"
    end

    within_authorizations_tab do
      expect(page).to have_content("Example authorization")
      expect(page).to have_content("Association only")
    end
  end

  it "enables multiple customizations and exposes all their authorizations" do
    within_customizations_tab do
      check "organization_birthdate_age_gates_enabled"
      check "organization_association_enabled"
      click_on "Save"
    end

    settings_updated_successfully!

    within_authorizations_tab do
      expect(page).to have_content("12 plus")
      expect(page).to have_content("16 plus")
      expect(page).to have_content("18 plus")
      expect(page).to have_content("Association only")
    end
  end
end
