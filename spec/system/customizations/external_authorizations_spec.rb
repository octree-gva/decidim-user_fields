# frozen_string_literal: true

require "spec_helper"

describe "External authorizations with customizations", :custom_user_fields_scenarios, type: :system do
  let(:organization) do
    create(:organization, available_authorizations: %w(dummy_authorization_handler sixteen_plus))
  end
  let(:user) { create(:user, :confirmed, organization:) }
  let(:participatory_process) { create(:participatory_process, :with_steps, organization:) }
  let!(:component) do
    create(
      :proposal_component,
      :with_creation_enabled,
      participatory_space: participatory_process,
      permissions: { create: { authorization_handlers: { dummy_authorization_handler: {} } } }
    )
  end

  before do
    enable_customization_for(organization, :neuchatel)
    switch_to_host(organization.host)
    login_as user, scope: :user
  end

  it "still allows dummy authorization flows when a customization is enabled" do
    visit main_component_path(component)
    click_on "New proposal"

    expect(page).to have_content("Authorization required")
    expect(page).to have_content("Example authorization")
    click_on 'Authorize with "Example authorization"'

    expect(page).to have_content("Verify with Example authorization")
    fill_in "Document number", with: "123456789X"
    fill_in_datepicker :authorization_handler_birthday_date, with: Time.current.change(day: 12).strftime("%d/%m/%Y")
    click_on "Send"

    expect(page).to have_content("You have been successfully authorized")
  end
end
