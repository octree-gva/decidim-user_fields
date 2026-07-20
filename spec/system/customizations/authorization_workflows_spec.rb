# frozen_string_literal: true

require "spec_helper"

describe "Scenario authorization workflows", :custom_user_fields_scenarios do
  let(:organization) { create(:organization, available_authorizations: %w(twelve_plus eighteen_plus location_validated association_only)) }
  let(:user) { create(:user, :confirmed, organization:) }

  before do
    switch_to_host(organization.host)
    login_as user, scope: :user
  end

  context "with birthdate age gates enabled" do
    before { enable_customization_for(organization, :birthdate_age_gates) }

    it "grants eighteen_plus when the user is old enough" do
      user.update!(extended_data: { birthdate_age_gates_birthdate: birthdate_for_age(20) })

      visit decidim_verifications.new_authorization_path(handler: "eighteen_plus")
      click_on "Send"

      expect(page).to have_content("You have been successfully authorized")
    end

    it "grants twelve_plus when the user is old enough" do
      visit decidim_verifications.new_authorization_path(handler: "twelve_plus")
      fill_custom_date_field("authorization_handler_birthdate", age: 13)
      click_on "Send"

      expect(page).to have_content("You have been successfully authorized")
    end
  end

  context "with location validation enabled" do
    before { enable_customization_for(organization, :location_validation) }

    it "validates the location fields format" do
      visit decidim_verifications.new_authorization_path(handler: "location_validated")

      fill_in :authorization_handler_birthdate, with: "31.12.1990"
      fill_in :authorization_handler_postal_code, with: "1003"
      fill_in :authorization_handler_full_name, with: "Ada Lovelace"
      click_on "Send"

      expect(page).to have_content("You have been successfully authorized")
    end
  end

  context "with association customization enabled" do
    before { enable_customization_for(organization, :association) }

    it "grants association_only when the user represents an association" do
      user.update!(extended_data: { association_represent_association: true })

      visit decidim_verifications.new_authorization_path(handler: "association_only")
      click_on "Send"

      expect(page).to have_content("You have been successfully authorized")
    end

    it "rejects association_only when the user does not represent an association" do
      user.update!(extended_data: { association_represent_association: false })

      visit decidim_verifications.new_authorization_path(handler: "association_only")
      click_on "Send"

      expect(page).to have_content("There was a problem creating the authorization")
    end
  end
end
