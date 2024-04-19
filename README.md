<h1 align="center"><img src="https://github.com/octree-gva/meta/blob/main/decidim/static/header.png?raw=true" alt="Decidim - Octree Participatory democracy on a robust and open source solution" /></h1>
<h4 align="center">
    <a href="https://www.octree.ch">Octree</a> |
    <a href="https://octree.ch/en/contact-us/">Contact Us</a> |
    <a href="https://blog.octree.ch">Our Blog (FR)</a><br/><br/>
    <a href="https://decidim.org">Decidim</a> |
    <a href="https://docs.decidim.org/en/">Decidim Docs</a> |
    <a href="https://meta.decidim.org">Participatory Governance (meta decidim)</a><br/><br/>
    <a href="https://matrix.to/#/+decidim:matrix.org">Decidim Community (Matrix+Element.io)</a>
</h4>
<p align="center">
    <a href="https://participe.gland.ch">
        <img
            src="https://github.com/octree-gva/meta/blob/main/decidim/static/participe_gland.png?raw=true"
            alt="Participe Gland — Donnez vie à vos idées avec le budget participatif" />
    </a>
    <a href="https://mkutano.community"><img src="https://github.com/octree-gva/decidim-module-mkutano_custom_registration_flow/blob/main/mkutano-logo.png?raw=true" alt="MKUTANO is a participatory platform where black canadians can effectively & democratically organize at scale" /></a>
    <a href="https://opencollective.com/voca">
        <img
            src="https://github.com/octree-gva/meta/blob/main/decidim/static/opencollective_chip.png?raw=true"
            alt="Voca – Open-Source SaaS platform for Decidim" />
    </a>
</p>


# Decidim User Fields
Add custom user fields, through configuration file and without migration. 
This module aims to configure in a blast new fields for subscription and profile edition. It supports: 

- User registration
- User profiles
- User invitations.

⚠️ It **does not support**:

- Omniauth registrations

## Setup the module
Add the gem to your gemfile
```
gem "decidim-user_fields"
```

Run bundle
```
bundle install
```

Create an initializer `config/initializers/custom_user_fields.rb`
```
Decidim::CustomUserFields.configure do |config|
    config.add_field :birthdate, type: :date, required: true
    config.add_field :province, type: :select, options: [:vd, :vs, :ar], default: :vd, required: true
    config.add_field :adress, type: :textarea, required: false, rows: 10
    config.add_field :purpose, type: :text, required: false
end
```

### Available field types

**`:date`**

parameters:
* `required`: must choose a date
* `min`: date in ISO8601 where the user can not select before
* `max`: date in ISO8601 where the user can not select after

**`:textarea`**

parameters:
* `required`: if the field is required
* `min`: minimal length
* `max`: maximal length
* `rows`: how much rows the field should display

**`:text`**

parameters:
* `required`: if the field is required

### Labels
Labels are translated, and are under the traduction scope `decidim.custom_user_fields`. 
Example of a `fr.yml` file:

```yml
fr:
  activemodel:
    attributes:
      user:
        birthday: "Birthday"
        adress: "Addresse"
        purpose: "Raison d'être ici"
        province: "Canton"
  decidim:
    custom_user_fields:
      province:
        options:
          vd: "Vaud"
          vs: "Valais"
          ar: "Aarau"
```

## Run locally
To run this module locally, we use docker-compose: 
```
docker-compose up
```
This will run a `decidim-user_fields` container, which sleeps.
You can run any command you want in the running container, like: 

- `docker-compose exec -it decidim-user_fields bundle exec rails db:seed`: seed the database (run on [`localhost:3000`](https://localhost:3000))
- `docker-compose exec -it decidim-user_fields bin/webpack-dev-server`: compile assets and watch for changes
- `docker-compose exec -it decidim-user_fields bin/rails s -b 0.0.0.0`: run rails server in development
- `docker-compose exec -it decidim-user_fields bundle exec rspec /home/decidim/module/spec`: run tests for the module
- `docker-compose exec -it decidim-user_fields bundle exec rubocop -a /home/decidim/module`: correct lint error with rubocop
- `docker-compose exec -it decidim-user_fields bash`: navigate your container in bash

While developping locally, you have two environments variables that can help you: 
- `ROOT`: the root of the application using the module
- `MODULE_ROOT`: the place where your gem code is.

