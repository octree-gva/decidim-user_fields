# frozen_string_literal: true

require "spec_helper"

describe "System organization customizations toggle", :custom_user_fields_scenarios, type: :system do
  let(:admin) { create(:admin) }
  let!(:organization) { create(:organization, available_authorizations: []) }

  before do
    login_as admin, scope: :admin
    visit decidim_system.edit_organization_path(organization)
  end

  it "enables a customization and exposes its authorizations in the authorizations tab" do
    click_on "User field customizations"
    check "organization_neuchatel_enabled"
    click_on "Save"

    settings_updated_successfully!

    click_on "Authorizations"
    expect(page).to have_content("12 plus")
    expect(page).to have_content("16 plus")
    expect(page).to have_content("18 plus")

    check "organization_available_authorizations_sixteen_plus"
    click_on "Save"

    settings_updated_successfully!
    expect(organization.reload.available_authorizations).to include("sixteen_plus")
  end

  it "blocks disabling a customization while its authorizations remain enabled" do
    enable_customization_for(organization, :neuchatel)
    organization.update!(available_authorizations: %w(sixteen_plus))

    visit decidim_system.edit_organization_path(organization)
    click_on "User field customizations"
    uncheck "organization_neuchatel_enabled"
    click_on "Save"

    expect(page).to have_content("Incompatible with enabled authorizations")
    expect(organization.reload.available_authorizations).to include("sixteen_plus")
  end

  it "keeps external authorizations available alongside customization workflows" do
    click_on "Authorizations"
    expect(page).to have_content("Example authorization")

    click_on "User field customizations"
    check "organization_gland_enabled"
    click_on "Save"

    click_on "Authorizations"
    expect(page).to have_content("Example authorization")
    expect(page).to have_content("Association only")
  end
end
