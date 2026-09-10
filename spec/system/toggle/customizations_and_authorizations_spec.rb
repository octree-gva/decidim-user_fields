# frozen_string_literal: true

require "spec_helper"

describe "System organization customizations toggle", :custom_user_fields_scenarios do
  let(:admin) { create(:admin) }
  let!(:organization) { create(:organization, available_authorizations: [], omniauth_settings: nil, favicon: nil) }

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

  it "hides and unselects authorizations when their customization is disabled" do
    enable_customization_for(organization, :birthdate_age_gates)
    organization.update!(available_authorizations: %w(sixteen_plus))

    visit decidim_system.edit_organization_path(organization)
    within_customizations_tab do
      uncheck "organization_birthdate_age_gates_enabled"
      click_on "Save"
    end

    settings_updated_successfully!
    expect(organization.reload.available_authorizations).not_to include("sixteen_plus")

    within_authorizations_tab do
      expect(page).to have_no_content("16 plus")
    end
  end

  it "does not list demo customization authorizations until the customization is enabled" do
    within_authorizations_tab do
      expect(page).to have_no_content("Location validated")
      expect(page).to have_no_content("12 plus")
      expect(page).to have_content("Example authorization")
    end
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

  it "does not render the ephemeral participation picker without the gem" do
    skip "decidim-ephemeral_participation is loaded" if ephemeral_participation_gem?

    within_authorizations_tab do
      expect(page).to have_no_css("input[id$='allow_ephemeral_participation']")
    end
  end

  it "renders the ephemeral participation picker and keeps Hash storage" do
    skip "requires decidim-ephemeral_participation" unless ephemeral_participation_gem?

    enable_customization_for(organization, :birthdate_age_gates)
    visit decidim_system.edit_organization_path(organization)

    within_authorizations_tab do
      expect(page).to have_css("input[id^='organization_available_authorizations_']")
      check "organization_available_authorizations_sixteen_plus"
      click_on "Save"
    end

    settings_updated_successfully!
    raw = organization.reload.read_attribute(:available_authorizations)
    expect(raw).to be_a(Hash)
    expect(raw.keys.map(&:to_s)).to include("sixteen_plus")
  end

  it "persists first_login_mode from the user fields tab" do
    within_customizations_tab do
      select "None", from: "First login mode"
      click_on "Save"
    end

    settings_updated_successfully!

    config = Decidim::Toggle::OrganizationModuleConfig.find_by!(
      decidim_organization_id: organization.id,
      module_name: "custom_user_fields"
    ).config
    expect(config.with_indifferent_access[:first_login_mode]).to eq("none")
  end
end
