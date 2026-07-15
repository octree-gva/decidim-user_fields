# frozen_string_literal: true

require "spec_helper"

describe "Custom user fields registration", :custom_user_fields_scenarios, type: :system do
  let!(:organization) { create(:organization) }
  let!(:terms_of_service_page) { Decidim::StaticPage.find_by(slug: "terms-of-service", organization:) }

  before do
    switch_to_host(organization.host)
  end

  context "with Neuchâtel customization enabled" do
    before { enable_customization_for(organization, :neuchatel) }

    it "shows an optional birthdate field" do
      visit decidim.new_user_registration_path

      expect_custom_date_field("registration_user_neuchatel_birthdate", label: "Birthdate")
    end

    it "registers without birthdate" do
      visit decidim.new_user_registration_path
      fill_registration_form_base(email: "neuchatel.optional@example.org")
      submit_registration_form

      expect(page).to have_content("confirmation link")
      user = Decidim::User.find_by(email: "neuchatel.optional@example.org")
      expect(user.extended_data["neuchatel_birthdate"]).to be_blank
    end

    it "registers with birthdate" do
      visit decidim.new_user_registration_path
      fill_registration_form_base(email: "neuchatel.with-date@example.org")
      fill_custom_date_field("registration_user_neuchatel_birthdate", age: 20)
      submit_registration_form

      expect(page).to have_content("confirmation link")
      user = Decidim::User.find_by(email: "neuchatel.with-date@example.org")
      expect(user.extended_data["neuchatel_birthdate"]).to eq(birthdate_for_age(20))
    end
  end

  context "with Lausanne customization enabled" do
    before { enable_customization_for(organization, :lausanne) }

    it "does not show registration fields" do
      visit decidim.new_user_registration_path
      expect(page).to have_no_field("registration_user_birthdate")
      expect(page).to have_no_field("registration_user_postal_code")
    end
  end

  context "with Gland customization enabled" do
    before { enable_customization_for(organization, :gland) }

    it "requires the association boolean on registration" do
      visit decidim.new_user_registration_path
      expect(page).to have_field("registration_user_gland_represent_association")

      fill_registration_form_base(email: "gland.missing@example.org")
      submit_registration_form

      expect(page).to have_current_path decidim.user_registration_path
    end

    it "registers when the association boolean is checked" do
      visit decidim.new_user_registration_path
      fill_registration_form_base(email: "gland.ok@example.org")
      check "registration_user_gland_represent_association"
      submit_registration_form

      expect(page).to have_content("confirmation link")
      user = Decidim::User.find_by(email: "gland.ok@example.org")
      expect(user.extended_data["gland_represent_association"]).to be(true)
    end
  end
end
