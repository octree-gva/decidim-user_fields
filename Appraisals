# frozen_string_literal: true

# Optional decidim-ephemeral_participation matrix (thoughtbot/appraisal).
#
# Default Gemfile has no ephemeral gem. This appraisal adds it so System →
# Authorizations can be verified with Hash storage and ephemeral radios.
#
#   bundle exec appraisal install
#   BUNDLE_GEMFILE=gemfiles/with_ephemeral.gemfile bundle exec rake test_app
#   BUNDLE_GEMFILE=gemfiles/with_ephemeral.gemfile bundle exec rspec
#
# Docker (CI parity):
#   docker compose -f docker-compose.ci.yml run --rm rspec
#   docker compose -f docker-compose.ci.yml run --rm -e BUNDLE_GEMFILE=gemfiles/with_ephemeral.gemfile rspec

appraise "with_ephemeral" do
  gem "decidim-ephemeral_participation",
      git: "https://git.octree.ch/decidim/vocacity/decidim-modules/decidim-ephemeral_participation",
      tag: "v0.0.9"
end
