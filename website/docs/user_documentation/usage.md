---
sidebar_position: 6
description: Use this module
---
## Registration field sets
Register named field sets in `config/initializers/custom_user_fields.rb`. Enable one per organization in **System → Organizations → Registration fields** (requires `decidim-toggle`).

```ruby
Decidim::CustomUserFields.register_field_set :default do |set|
  set.add_field :birthdate, type: :date, required: true
  set.add_field :address, type: :textarea, required: false, rows: 10
  set.add_field :purpose, type: :text, required: false
end
```


### Available field types

**`:date`**

parameters:
* `required`: must choose a date
* `not_before`: date in ISO8601 where the user cannot select before
* `not_after`: date in ISO8601 where the user cannot select after
* `skip_hashing`: Do not hash the field result (watch out privacy concerns)

**`:textarea`**
a textarea field, which the content will be trimmed (no whitespaces before and after).

parameters:
* `required`: if the field is required
* `min`: minimal text length
* `max`: maximal text length
* `skip_hashing`: Do not hash the field result (watch out privacy concerns)
* `ui.rows`: how many rows the field should display

**`:text`**
a text field, which the content will be trimmed (no whitespaces before and after).

parameters:
* `required`: if the field is required
* `values_in`: restrict the values accepted for the field
* `format`: a regex (like `format: /\A[A-z0-9]*\z/)
* `skip_hashing`: Do not hash the field result (watch out privacy concerns)

**`:extra_field_ref` (Authorization only)**
> This field is a quiet special one, it allows workflows where
> the extra_field on registration is optional, but get required on authorization.
> Warning: this field can be use only in authorization configuration

parameters:
* `ref`: the extra_field reference name
* `hide_if_value`: hide the extra field if there is already a value.
* `skip_hashing`: Do not hash the field result (watch out privacy concerns)
* `skip_update_on_verified`: Do not update the extra_field reference when verified
* `...`: any other parameters to override the reference option


### Labels
Labels are translated and are under the translation scope `decidim.custom_user_fields`. 
Example of a `config/locales/fr.yml` file:

```yml
fr:
  decidim:
    authorization_handlers:
      pb2024:
        name: "Données de rescencement pour le Budget Participatif 2024"
        explanation: "Donnée récoltée pour participer au BP 2024"
    custom_user_fields:
      extended_data:
        first_name:
          label: "Prénoms"
        last_name:
          label: "Nom de famille"
      pb2024:
        birthdate:
          label: "Date de naissance"
          help_text: "La participation est réservée aux personnes de plus de 18ans"
        postal_code:
          label: "Code postal"
          help_text: "La participation est réservée aux habitants de MaCommune.
```

# Create an authorization with custom fields

```ruby
Decidim::CustomUserFields.register_field_set :pb2024_profile do |set|
  set.add_field :first_name, type: :text, required: false
  set.add_field :last_name, type: :text, required: false
end

Rails.application.config.after_initialize do
  Decidim::CustomUserFields::Verifications.register("PB2024") do |config|
    config.field_set :pb2024_profile
    config.add_field :first_name, type: :extra_field_ref, required: true, skip_hashing: true, hide_if_value: true
    config.add_field :last_name, type: :extra_field_ref, required: true, skip_hashing: true, hide_if_value: true
    config.add_field :birthdate, type: :date, required: true, not_after: 18.years.ago.to_date.iso8601
    config.add_field :postal_code, type: :text, required: true, format: /\A[\-0-9]*\z/, values_in: ["2000", "2001", "2002"]
  end
end

```

Then, add locales for this flow: 
```yml
fr:
  decidim:
    authorization_handlers:
      pb2024:
        name: "Participer au BP 2024"
        explanation: "Valider votre compte"
    custom_user_fields:
      first_name:
        label: Prénoms
        help_text: Ce champs est requis pour participer aux budgets participatif.
      last_name: 
        label: Nom de famille
    pb2024:
      birthdate:
        label: Date de naissance
        bad_not_after: Seul les > 18 peuvent participer
      postal_code:
        label: Code postal
        bad_values: Ce code postal est inconu dans  maCommune
        help_text: Seul les communies prêt de maCommune peux être acceptée
```
