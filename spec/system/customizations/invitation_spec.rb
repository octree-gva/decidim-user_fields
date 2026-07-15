# frozen_string_literal: true

require "spec_helper"

describe "Custom user fields invitation acceptance", :custom_user_fields_scenarios, type: :system do
  let!(:organization) { create(:organization) }
  let!(:private_assembly) { create(:assembly, :published, organization:, private_space: true) }
  let!(:inviter) { create(:user, :admin, :confirmed, organization:) }

  before do
    enable_customization_for(organization, :gland)
    switch_to_host(organization.host)
  end

  it "shows custom registration fields when accepting a private assembly invitation" do
    invited = Decidim::User.invite!(
      {
        email: "private.assembly@example.org",
        name: "Private Assembly User",
        organization:
      },
      inviter
    )
    create(:assembly_private_user, user: invited, privatable_to: private_assembly)

    visit "/users/invitation/accept?invitation_token=#{invited.raw_invitation_token}"

    expect(page).to have_field("invitation_user_gland_represent_association")
    expect(page).to have_content("I represent an association")

    fill_in :invitation_user_nickname, with: "private_asm_user"
    fill_in :invitation_user_password, with: "decidim123456789"
    check "invitation_user_gland_represent_association"
    check :invitation_user_tos_agreement
    click_on "Save"

    expect(page).to have_content("Your password was set successfully")
    expect(invited.reload.extended_data["gland_represent_association"]).to be(true)
  end
end
