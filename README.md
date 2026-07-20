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
- Omniauth registration (OIDC profile completion after IdP sign-in)

> Are you on GitHub ? Please use the reference repository on [GitLab for issues and pull requests](https://git.octree.ch/decidim/vocacity/decidim-modules/decidim-user_fields).

All the information to use the gem is on our [documentation website](https://octree-gva.github.io/decidim-user_fields)

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

Admin toggle labels: `decidim_toggle.system.custom_user_fields.<name>_enabled`.
Customization display labels (`Customization#label`): `decidim.custom_user_fields.customizations.<name>`.

Full key list and how to run `i18n-tasks missing` (customization registry scanner): see the [Translate](https://octree-gva.github.io/decidim-user_fields/dev_documentation/locales) docs page.

Sysadmins enable or disable whole customizations per organization; authorizations bundled in a customization are toggled together with it.

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

## Try Omniauth locally (Zitadel + Docker)

**Prerequisite:** Docker and Docker Compose.

`docker compose up` starts infrastructure only (Postgres, Zitadel, MailCatcher). It does **not** start Decidim — there is no idle `decidim` service in the default stack.

### Quick start

One command — setup (~5–10 min first time) then Decidim on http://localhost:3000:

```bash
./bin/dev-oidc-up
```

Idempotent: safe to re-run when the stack is already up.

### What `./bin/dev-oidc-up` does

| Step | Action | Output |
|------|--------|--------|
| 1 | Start Zitadel stack | Zitadel on :8080, admin PAT in `docker/zitadel/bootstrap/admin.pat` |
| 2 | Configure Zitadel SMTP + OIDC app | `docker/zitadel/oidc.env` (gitignored) |
| 3 | `rake test_app` (first time only) | Dummy app in `spec/decidim_dummy_app` |
| 4 | `dev:prepare_secrets`, `db:schema:load` | Empty Decidim schema |
| 5 | `dev:seed` | Minimal org + admin + Zitadel provider + **association** scenario |
| 6 | `docker compose --profile dev run --rm --service-ports decidim … rails s` | Rails on http://localhost:3000 (foreground) |

### URLs and credentials

| URL | Purpose |
|-----|---------|
| http://localhost:3000 | Decidim dummy app |
| http://localhost:8080 | Zitadel console |
| http://localhost:1080 | MailCatcher (emails) |

| Account | Login |
|---------|-------|
| Decidim admin | `admin@example.org` / `decidim123456789` |
| Zitadel admin | `admin@zitadel.localhost` / `Password1!` |

### Experiment: OIDC sign-in → custom fields

1. Open http://localhost:8080, sign in as Zitadel admin.
2. **Users → New** — create a test user (email + password).
3. Open http://localhost:3000/users/sign_in, click **Zitadel**, sign in with that user.
4. Complete the profile form — the association demo shows the “I represent an association” checkbox.
5. Optional: verify authorization at http://localhost:3000/account/authorizations/new?handler=association_only (after checking the boolean on registration).

Change the seeded scenario (e.g. optional birthdate + age authorizations):

```bash
DEV_CUSTOMIZATION=birthdate_age_gates ./bin/dev-oidc-up
```

### Environment variables (local OIDC)

| Variable | Default | Required | Purpose |
|----------|---------|----------|---------|
| `DEV_CUSTOMIZATION` | `association` | no | Scenario customization enabled by `dev:seed` (`association`, `birthdate_age_gates`, `location_validation`) |
| `DECIDIM_HOST` | `localhost` | no | Organization host matched by `dev:seed` |
| `ZITADEL_OIDC_ENABLED` | set in compose | no | Loads dev OIDC middleware + scenario customizations |
| `ZITADEL_URL` | `http://localhost:8080` | no | Zitadel API base URL used by `dev-oidc-up` |
| `OIDC_ISSUER` | `http://localhost:8080` | no | Public issuer written to `oidc.env` |
| `OIDC_REDIRECT_URI` | `http://localhost:3000/users/auth/openid_connect/callback` | no | OIDC redirect URI for the Zitadel app |

Generated at setup time (do not commit): `docker/zitadel/oidc.env` — see `docker/zitadel/oidc.env.example`.

### Troubleshooting

| Symptom | Fix |
|---------|-----|
| No **Zitadel** button on sign-in | Re-run `./bin/dev-oidc-up` |
| `Missing docker/zitadel/oidc.env` | Re-run `./bin/dev-oidc-up` (Zitadel must be ready first) |
| `Missing PAT at docker/zitadel/bootstrap/admin.pat` | `docker compose down -v` then `./bin/dev-oidc-up` |
| Zitadel not ready yet | Wait 1–2 min on first boot; check http://localhost:8080/debug/ready |
| `connection refused` to `localhost:8080` on Zitadel login | Re-run `./bin/dev-oidc-up` — token/userinfo must use `zitadel:8080` inside Docker |
| Zitadel login fails with `"Unknown"` / `Instance not found` | Ensure `ZITADEL_PUBLIC_HOST=localhost:8080` on the Decidim container (Host header for internal calls) |
| OIDC completes custom fields but asks for email confirmation | Re-run `./bin/dev-oidc-up` after updating the gem — OpenID Connect verified emails should sign you in directly |
| Port 3000 empty | Do not use plain `docker compose up` (no Rails service without a profile) — use `./bin/dev-oidc-up` |
| `network … not found` when starting Rails | Stale compose network after one-shots — re-run `./bin/dev-oidc-up` (script no longer uses `profile web up`) |
| `decidim_users already exists` on setup | Re-run `docker compose down -v && ./bin/dev-oidc-up` (script now runs `db:schema:load`) |
| `A server is already running` / stale `server.pid` | `rm -f spec/decidim_dummy_app/tmp/pids/server.pid` then re-run `./bin/dev-oidc-up` |

Reset all local data: `docker compose down -v` then `./bin/dev-oidc-up`.

## How to add a custom user field

Create an initializer `config/initializers/custom_user_fields.rb`:

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

## Module development (specs, shell)

For **OIDC experimentation**, use [Try Omniauth locally](#try-omniauth-locally-zitadel--docker) above.

The `decidim` compose service is the OIDC/dev container (shell or Rails). `./bin/dev-oidc-up` starts Rails with `compose run --service-ports`.

```bash
# Interactive shell in the dev container
docker compose --profile dev run --rm decidim bash

# Rails only (infra must already be up — e.g. after a partial setup)
docker compose --profile dev run --rm --service-ports decidim bash -c \
  "cd /home/module/spec/decidim_dummy_app && rm -f tmp/pids/server.pid && bundle exec rails server -b 0.0.0.0 -p 3000"

# Specs (from repo root, dummy app Gemfile)
docker compose --profile dev run --rm decidim bash -c \
  "cd /home/module && BUNDLE_GEMFILE=spec/decidim_dummy_app/Gemfile bundle exec rspec"
```

Useful paths inside the container:

| Path | Purpose |
|------|---------|
| `/home/module` | This gem (mounted from the repo) |
| `/home/module/spec/decidim_dummy_app` | Dummy Decidim app used for local OIDC + specs |

Environment variables in the dev image:

| Variable | Purpose |
|----------|---------|
| `DEV_MODULE` | Gem under development (`decidim-user_fields`) |
| `DECIDIM_VERSION` | Decidim release used by the dummy app |
