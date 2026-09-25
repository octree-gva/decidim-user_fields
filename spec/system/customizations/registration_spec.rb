# frozen_string_literal: true

require "spec_helper"

describe "Custom user fields registration", :custom_user_fields_scenarios do
  let!(:organization) { create(:organization, favicon: nil) }
  let!(:terms_of_service_page) { Decidim::StaticPage.find_by(slug: "terms-of-service", organization:) }

  before do
    switch_to_host(organization.host)
  end

  context "with birthdate age gates customization enabled" do
    before { enable_customization_for(organization, :birthdate_age_gates) }

    it "shows an optional birthdate field" do
      visit decidim.new_user_registration_path

      expect_custom_date_field("registration_user_birthdate_age_gates_birthdate", label: "Birthdate")
    end

    it "registers without birthdate" do
      visit decidim.new_user_registration_path
      fill_registration_form_base(email: "birthdate.optional@example.org")
      submit_registration_form

      expect(page).to have_content("confirmation link")
      user = Decidim::User.find_by(email: "birthdate.optional@example.org")
      expect(user.extended_data["birthdate_age_gates_birthdate"]).to be_blank
    end

    it "registers with birthdate" do
      visit decidim.new_user_registration_path
      fill_registration_form_base(email: "birthdate.with-date@example.org")
      fill_custom_date_field("registration_user_birthdate_age_gates_birthdate", age: 20)
      submit_registration_form

      expect(page).to have_content("confirmation link")
      user = Decidim::User.find_by(email: "birthdate.with-date@example.org")
      expect(user.extended_data["birthdate_age_gates_birthdate"]).to eq(birthdate_for_age(20))
    end
  end

  context "with location validation customization enabled" do
    before { enable_customization_for(organization, :location_validation) }

    it "does not show registration fields" do
      visit decidim.new_user_registration_path
      expect(page).to have_no_field("registration_user_birthdate")
      expect(page).to have_no_field("registration_user_postal_code")
    end
  end

  context "with association customization enabled" do
    before { enable_customization_for(organization, :association) }

    it "requires the association boolean on registration" do
      visit decidim.new_user_registration_path
      expect(page).to have_field("registration_user_association_represent_association")

      fill_registration_form_base(email: "association.missing@example.org")
      submit_registration_form

      expect(page).to have_current_path decidim.user_registration_path
    end

    it "registers when the association boolean is checked" do
      visit decidim.new_user_registration_path
      fill_registration_form_base(email: "association.ok@example.org")
      check "registration_user_association_represent_association"
      submit_registration_form

      expect(page).to have_content("confirmation link")
      user = Decidim::User.find_by(email: "association.ok@example.org")
      expect(user.extended_data["association_represent_association"]).to be(true)
    end
  end

  context "with association customization enabled instead of birthdate" do
    before { enable_customization_for(organization, :association) }

    it "shows the association field and not the birthdate field" do
      visit decidim.new_user_registration_path
      expect(page).to have_field("registration_user_association_represent_association")
      expect(page).to have_no_field("registration_user_birthdate_age_gates_birthdate_date")
    end
  end
end
