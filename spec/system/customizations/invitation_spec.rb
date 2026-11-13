# frozen_string_literal: true

require "spec_helper"

describe "Custom user fields invitation acceptance", :custom_user_fields_scenarios do
  let!(:organization) { create(:organization) }
  let!(:private_assembly) { create(:assembly, :published, organization:, access_mode: :restricted) }
  let!(:inviter) { create(:user, :admin, :confirmed, organization:) }

  before do
    enable_customization_for(organization, :association)
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
    create(:member, user: invited, participatory_space: private_assembly, published: true)

    visit "/users/invitation/accept?invitation_token=#{invited.raw_invitation_token}"

    expect(page).to have_field("invitation_user_association_represent_association")
    expect(page).to have_content("I represent an association")

    fill_in :invitation_user_nickname, with: "private_asm_user"
    fill_in :invitation_user_password, with: "decidim123456789"
    check "invitation_user_association_represent_association"
    check :invitation_user_tos_agreement
    click_on "Save"

    expect(page).to have_content("Invitation accepted successfully")
    expect(invited.reload.extended_data["association_represent_association"]).to be(true)
  end

  it "shows validation errors for required custom fields" do
    invited = Decidim::User.invite!(
      {
        email: "private.assembly.invalid@example.org",
        name: "Private Assembly User",
        organization:
      },
      inviter
    )
    create(:member, user: invited, participatory_space: private_assembly, published: true)

    visit "/users/invitation/accept?invitation_token=#{invited.raw_invitation_token}"

    fill_in :invitation_user_nickname, with: "private_asm_user"
    fill_in :invitation_user_password, with: "decidim123456789"
    check :invitation_user_tos_agreement
    click_on "Save"

    expect(page).to have_no_content("Invitation accepted successfully")
    expect(page).to have_content("This field is required")
    expect(page).to have_field("invitation_user_association_represent_association")
    expect(invited.reload.extended_data).to be_blank
  end
end
