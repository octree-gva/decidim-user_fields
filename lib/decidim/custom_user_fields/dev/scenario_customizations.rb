# frozen_string_literal: true

module Decidim
  module CustomUserFields
    module ScenarioCustomizations
      class << self
        def register!
          return if Customizations.find(:neuchatel)

          register_neuchatel!
          register_lausanne!
          register_gland!
          refresh_form_definitions!
        end

        def refresh_form_definitions!
          [
            Decidim::RegistrationForm,
            Decidim::OmniauthRegistrationForm,
            Decidim::AccountForm
          ].each { |form_class| FormDefinition.setup_form_class(form_class) }
        end

        private

        def register_neuchatel!
          Decidim::CustomUserFields.register_customization(:neuchatel) do |customization|
            customization.registration_fields do |set|
              set.add_field :birthdate, type: :date, required: false
            end

            { "TwelvePlus" => 12, "SixteenPlus" => 16, "EighteenPlus" => 18 }.each do |authorization_name, years|
              customization.authorization authorization_name do |config|
                config.add_field :birthdate,
                                 type: :extra_field_ref,
                                 ref: :birthdate,
                                 required: true,
                                 not_after: years.years.ago.to_date.iso8601
              end
            end
          end
        end

        def register_lausanne!
          Decidim::CustomUserFields.register_customization(:lausanne) do |customization|
            customization.authorization "LocationValidated" do |config|
              config.add_field :birthdate, type: :text, required: true, format: /\A\d{2}\.\d{2}\.\d{4}\z/
              config.add_field :postal_code, type: :text, required: true
              config.add_field :full_name, type: :text, required: true
            end
          end
        end

        def register_gland!
          Decidim::CustomUserFields.register_customization(:gland) do |customization|
            customization.registration_fields do |set|
              set.add_field :represent_association, type: :boolean, required: true
            end

            customization.authorization "AssociationOnly" do |config|
              config.add_field :represent_association,
                               type: :extra_field_ref,
                               ref: :represent_association,
                               required: true,
                               must_be_true: true
            end
          end
        end
      end
    end
  end
end
