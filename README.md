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

## Install the module
Add the gem to your Gemfile
```ruby
gem "decidim-user_fields"
```

Run bundle
```bash
bundle install
```

## How to add a custom user field.
Create an initializer `config/initializers/custom_user_fields.rb`
```ruby
Decidim::CustomUserFields.configure do |config|
  config.add_field :birthdate, type: :date, required: true
  config.add_field :address, type: :textarea, required: false, rows: 10
  config.add_field :purpose, type: :text, required: false
end
```


### Available field types

**`:date`**

parameters:
* `required`: must choose a date
* `min`: date in ISO8601 where the user cannot select before
* `max`: date in ISO8601 where the user cannot select after

**`:textarea`**

parameters:
* `required`: if the field is required
* `min`: minimal length
* `max`: maximal length
* `rows`: how many rows the field should display

**`:text`**

parameters:
* `required`: if the field is required

### Labels
Labels are translated and are under the translation scope `decidim.custom_user_fields`. 
Example of a `config/locales/fr.yml` file:

```yml
fr:
  activemodel:
    attributes:
      user:
        birthday: "Birthday"
        address: "Address"
        purpose: "Reason for Being Here"
        province: "Canton"
  decidim:
    custom_user_fields:
      province:
        options:
          vd: "Vaud"
          vs: "Valais"
          ar: "Aarau"
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
