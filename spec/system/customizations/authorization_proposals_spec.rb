# frozen_string_literal: true

require "spec_helper"

describe "Custom authorization on proposals", :custom_user_fields_scenarios, type: :system do
  let(:organization) { create(:organization, available_authorizations: %w(sixteen_plus eighteen_plus twelve_plus)) }
  let(:user) { create(:user, :confirmed, organization:) }
  let(:participatory_process) { create(:participatory_process, :with_steps, organization:) }
  let!(:component) do
    create(
      :proposal_component,
      :with_creation_enabled,
      participatory_space: participatory_process,
      permissions: { create: { authorization_handlers: { sixteen_plus: {} } } }
    )
  end

  before do
    enable_customization_for(organization, :birthdate_age_gates)
    switch_to_host(organization.host)
    login_as user, scope: :user
  end

  it "requires completing the sixteen_plus authorization before creating a proposal" do
    visit main_component_path(component)
    click_on "New proposal"

    expect(page).to have_content("Authorization required")
    expect(page).to have_content("16 plus")
    click_on 'Authorize with "16 plus"'

    expect(page).to have_content("Verify with 16 plus")
    fill_custom_date_field("authorization_handler_birthdate", age: 20)
    click_on "Send"

    expect(page).to have_content("You have been successfully authorized")

    visit main_component_path(component)
    click_on "New proposal"

    expect(page).to have_css("h1", text: "Create your proposal")
  end

  it "rejects authorization when the user is too young" do
    visit decidim_verifications.new_authorization_path(handler: "sixteen_plus")

    fill_custom_date_field_iso("authorization_handler_birthdate", birthdate_too_young_for_age(16))
    click_on "Send"

    expect(page).to have_content("There was a problem creating the authorization")
  end
end
