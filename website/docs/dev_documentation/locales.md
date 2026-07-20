---
sidebar_position: 3
description: How to translate this module
---

# Translate!
[![Crowdin](https://badges.crowdin.net/decidim-user-fields/localized.svg)](https://crowdin.com/project/decidim-user-fields)

We appreciate your interest in contributing to the translation of Decidim User Fields. Our aim is to make Decidim User Fields accessible to users around the world, and your help in this endeavor is invaluable.

Decidim User Fields utilizes [Crowdin](https://crowdin.com/project/decidim-user-fields), a leading platform for collaborative translation projects. Currently, we have translations in over 3 languages, and hope we will get more soon.

If you're interested in joining this global effort, here's how you can contribute:

    * Join the project: Access [the Crowdin project page](https://crowdin.com/project/decidim-user-fields), and click "Go to Editor". You will need to create an account in Crowdin if you haven't already one.

    * Start translating: After opening the editor, you can start translating. Whether you're helping to translate a new language or improving existing translations, your contribution will make a significant impact.

    * Your work will be reviewed and merge in the next minor version. Usually, we take up to 10 working days to release new minor versions. If you are in hurry, please send us an email at [support@octree.ch](mailto:support@octree.ch)

By contributing to the translation of Decidim User Fields, you're not just translating words; you're helping to break down language barriers and making this module more accessible to users around the world.

Thank you for your interest, and we look forward to your contribution!

## Customization keys (integrators)

Customization names, field names, and authorization handlers are registered at runtime. Labels are looked up from those names, so static analysis alone cannot see them. This module feeds the customization registry into [i18n-tasks](https://github.com/glebm/i18n-tasks) via a custom scanner.

### Required key shapes

For each `register_customization :name`:

| Surface | Key |
|--------|-----|
| Admin toggle checkbox | `decidim_toggle.system.custom_user_fields.<name>_enabled` |
| Customization label | `decidim.custom_user_fields.customizations.<name>` |
| Registration field label | `decidim.custom_user_fields.extended_data.<name>_<field>.label` |
| Authorization field label | `decidim.custom_user_fields.<handler>.<field>.label` |
| Authorization handler name | `decidim.authorization_handlers.<handler>.name` |
| Authorization handler explanation | `decidim.authorization_handlers.<handler>.explanation` |

Registration field names are prefixed with the customization name (for example `:community` + `:social_url` → `community_social_url`).

### Check missing keys

From the gem (Docker Compose; `ENGINE_ROOT=/home/module` is set in `docker-compose.yml`):

```bash
docker compose run --rm --entrypoint "" decidim bundle exec i18n-tasks missing
```

This uses `config/i18n-tasks.yml`, which registers the customization scanner. The scanner boots the dummy app when Rails is not already loaded so registered customizations are visible. If the registry cannot load, registry-derived keys are skipped and a warning is printed on stderr.

Host applications: keep your own locale `data.read` paths, and add this to `config/i18n-tasks.yml`:

```erb
<% require "decidim/custom_user_fields/i18n/tasks" %>
```

Then run `bundle exec i18n-tasks missing` after your initializers have registered customizations.
