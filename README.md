<h1 align="center"><img src="https://github.com/octree-gva/meta/blob/main/decidim/static/header.png?raw=true" alt="Decidim - Octree: Participatory Democracy on a Robust and Open Source Solution" /></h1>
<h4 align="center">
    <a href="https://www.octree.ch">Octree</a> |
    <a href="https://octree.ch/en/contact-us/">Contact Us</a> |
    <a href="https://blog.octree.ch">Our Blog (FR)</a><br/><br/>
    <a href="https://decidim.org">Decidim</a> |
    <a href="https://docs.decidim.org/en/">Decidim Docs</a> |
    <a href="https://meta.decidim.org">Participatory Governance (Meta Decidim)</a><br/><br/>
    <a href="https://matrix.to/#/+decidim:matrix.org">Decidim Community (Matrix+Element.io)</a>
</h4>
<p align="center">
    <a href="https://participe.gland.ch">
        <img
            src="https://github.com/octree-gva/meta/blob/main/decidim/static/participe_gland.png?raw=true"
            alt="Participe Gland — Give Life to Your Ideas with the Participatory Budget" />
    </a>
    <a href="https://mkutano.community"><img src="https://github.com/octree-gva/decidim-module-mkutano_custom_registration_flow/blob/main/mkutano-logo.png?raw=true" alt="MKUTANO is a participatory platform where Black Canadians can effectively & democratically organize at scale" /></a>
    <a href="https://opencollective.com/voca">
        <img
            src="https://github.com/octree-gva/meta/blob/main/decidim/static/opencollective_chip.png?raw=true"
            alt="Voca – Open-Source SaaS Platform for Decidim" />
    </a>
</p>

# Decidim User Fields
This Decidim module adds custom user fields through a configuration file and without migration. This module aims to configure in a blast new fields for subscription and profile editing. It supports: 

- User registration
- User profiles
- User invitations

⚠️ It **does not support**:

- Omniauth registrations

> Are you on GitHub ? Please use the reference repository on [GitLab for issues and pull requests](https://git.octree.ch/decidim/vocacity/decidim-modules/decidim-user_fields).


## Install the module
Add the gems to your Gemfile
```ruby
gem "decidim-user_fields"
gem "decidim-toggle",
    git: "https://git.octree.ch/decidim/vocacity/decidim-modules/decidim-toggle",
    branch: "main"
```

Run bundle and install toggle migrations:
```bash
bundle install
rails decidim_toggle:install:migrations
rails db:migrate
```

## Customizations (per organization)

Register named customizations in an initializer. Each customization bundles registration/profile fields and authorization workflows. Sysadmins enable them per organization in **System → Organizations → User field customizations** (via decidim-toggle).

```ruby
Decidim::CustomUserFields.register_customization :community do |customization|
  customization.registration_fields do |set|
    set.add_field :social_media_url, type: :text, required: false
  end
end

Decidim::CustomUserFields.register_customization :ngos do |customization|
  customization.registration_fields do |set|
    set.add_field :organization_name, type: :text, required: true
    set.add_field :organization_email, type: :text, required: true
  end

  customization.authorization "NgoVerify" do |config|
    config.add_field :organization_name, type: :extra_field_ref, ref: :organization_name, required: true
  end
end
```

Customization labels for the admin toggles: `decidim.custom_user_fields.customizations.<name>`.

Disabling a customization is blocked while the organization still has that customization's authorization workflows enabled.

## Upgrading from field sets to customizations

User values in `extended_data` and existing authorization grants are unchanged when field and handler names stay the same.

Toggle config migrates from `{ "active_field_set": "default" }` to `{ "default_enabled": true }`.

On deploy, `bin/rails decidim:upgrade` (or `decidim:update`) runs `decidim_custom_user_fields:upgrade:migrate_toggle_config` automatically.

Until that runs, the module still reads `active_field_set` when no `{name}_enabled` keys exist.

Manual run:

```bash
bin/rails decidim_custom_user_fields:upgrade:migrate_toggle_config
DRY_RUN=1 bin/rails decidim_custom_user_fields:upgrade:migrate_toggle_config
```

Refactor your initializer from `register_field_set` to `register_customization`, keeping the same customization name as the former field set (e.g. `:default`).

## Local testing with Zitadel (OIDC)

Docker Compose ships a Zitadel IdP, MailCatcher, and seed scripts for manual end-to-end testing (OIDC login → custom field completion → authorizations).

First-time setup (generates the dummy app if needed, ~5–10 min):

```bash
./bin/dev-local-setup
```

Then start Decidim:

```bash
docker compose --profile web up web
```

| URL | Purpose |
|-----|---------|
| http://localhost:3000 | Decidim dummy app |
| http://localhost:8080 | Zitadel console |
| http://localhost:1080 | MailCatcher (emails) |

Default credentials:

- **Zitadel admin:** `admin@zitadel.localhost` / `Password1!`
- **Decidim admin:** `admin@example.org` / `decidim123456789`

The setup script:

1. Starts Zitadel + Postgres + MailCatcher
2. Creates the OIDC app (`docker/zitadel/oidc.env`)
3. Seeds the demo org with Zitadel as `openid_connect` provider
4. Enables the **Gland** scenario customization (`DEV_CUSTOMIZATION=gland` by default)

Use a Zitadel user (create one in the console) to sign in via **Zitadel** on the Decidim login page. Missing custom fields appear on the OIDC completion form.

Individual steps:

```bash
docker compose up -d zitadel zitadel-db mailcatcher user-fields-pg
./bin/setup-zitadel-oidc          # writes docker/zitadel/oidc.env
cd spec/decidim_dummy_app
bundle exec rake decidim_custom_user_fields:dev:prepare_secrets
bundle exec rake decidim_custom_user_fields:dev:seed
```

Reset Zitadel data: `docker compose down -v` (re-runs first-instance bootstrap).

## How to add a custom user field.
Create an initializer `config/initializers/custom_user_fields.rb`
```ruby
Decidim::CustomUserFields.register_customization :default do |customization|
  customization.registration_fields do |set|
    set.add_field :birthdate, type: :date, required: true
    set.add_field :address, type: :textarea, required: false, rows: 10
    set.add_field :purpose, type: :text, required: false
  end
end
```
## Renewable verifications
To set an authorization as renewable, register it inside a customization and use `renewable!(time_between_renew)`:
```
Decidim::CustomUserFields.register_customization :pb2024 do |customization|
  customization.registration_fields { |set| set.add_field :foo, type: :text }
  customization.authorization "PB2024" do |config|
    config.renewable!(2.days) # Will need to renew authorization after 2 days.
  end
end
```
This will have no effect under < 30, or without the `decidim-ephemerable` gem. 



## Ephemerable verifications
To set an authorization as ephemerable, register it inside a customization and use `ephemerable!`:
```
Decidim::CustomUserFields.register_customization :pb2024 do |customization|
  customization.registration_fields { |set| set.add_field :foo, type: :text }
  customization.authorization "PB2024" do |config|
    config.ephemerable!
    config.renewable!(1.day) # The ephemerable will be valid for a day
  end
end
```
This will have no effect under < 30, or without the `decidim-ephemerable` gem. 

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
Decidim::CustomUserFields.register_customization :pb2024 do |customization|
  customization.registration_fields do |set|
    set.add_field :first_name, type: :text, required: false
    set.add_field :last_name, type: :text, required: false
  end

  customization.authorization "PB2024" do |config|
    config.ephemerable!
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

# Run locally
To run this module locally, we use Docker-compose:

```bash
docker-compose up
```
This will run a decidim-user_fields container, which **sleeps and does nothing**.

After your containers are mounted, you can seed the database: 
```bash
  docker-compose exec -it decidim-user_fields bin/rails db:seed
```

Then, you can start the server
```bash
  docker-compose exec -it decidim-user_fields bin/rails s -b 0.0.0.0
```

You can then open a bash session and edit the initializer, as described in the "How to add a custom user field" section. 
```bash
  docker-compose exec -it decidim-user_fields bash
```

Once something change, reset your server: 
```bash
  docker-compose exec -it decidim-user_fields bin/rails restart
```
While developing locally, you have two environment variables that can help you:

* `ROOT`: the root of the application using the module
* `MODULE_ROOT`: the place where your gem code is.



### Usefull commands

| Command                                                                                          | Description                                         |
|--------------------------------------------------------------------------------------------------|-----------------------------------------------------|
| `docker-compose exec -it decidim-user_fields bundle exec rails db:seed`                          | Seed the database (run on localhost:3000)           |
| `docker-compose exec -it decidim-user_fields bin/webpack-dev-server`                             | Compile assets and watch for changes                |
| `docker-compose exec -it decidim-user_fields bin/rails s -b 0.0.0.0`                             | Run the Rails server in development                 |
| `docker-compose exec -it decidim-user_fields bundle exec rspec /home/decidim/module/spec`        | Run tests for the module                            |
| `docker-compose exec -it decidim-user_fields bundle exec rubocop -a /home/decidim/module`        | Correct lint errors with RuboCop                    |
| `docker-compose exec -it decidim-user_fields bash`                                               | Navigate your container in bash                     |




While developing locally, you have two environment variables that can help you:

* `ROOT`: the root of the application using the module
* `MODULE_ROOT`: the place where your gem code is.
