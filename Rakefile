# frozen_string_literal: true

require "decidim/dev/common_rake"

def install_module(path)
  Dir.chdir(path) do
    Bundler.with_unbundled_env do
      sh "bundle exec rails decidim_toggle:install:migrations"
    end
  end
end

def seed_db(path)
  Dir.chdir(path) do
    raise "db:seed failed" unless system("bundle exec rails db:seed")
  end
end

desc "Prepare for testing"
task :prepare_tests do
  # Remove previous existing db, and recreate one.
  disable_docker_compose = ENV.fetch("DISABLED_DOCKER_COMPOSE", "false") == "true"
  unless disable_docker_compose
    sh "docker compose -f docker-compose.yml down -v"
    sh "docker compose -f docker-compose.yml up -d --remove-orphans"
  end
  ENV["RAILS_ENV"] = "test"
  test_db = {
    "adapter" => "postgresql",
    "encoding" => "unicode",
    "host" => ENV.fetch("DATABASE_HOST", "localhost"),
    "port" => ENV.fetch("DATABASE_PORT", "5432").to_i,
    "username" => ENV.fetch("DATABASE_USERNAME", "decidim"),
    "password" => ENV.fetch("DATABASE_PASSWORD", "TEST-baeGhi4Ohtahcee5eejoaxaiwaezaiGo"),
    "database" => "decidim_test",
    # GitLab/docker Postgres services rarely offer TLS on the internal hostname
    "sslmode" => ENV.fetch("DATABASE_SSLMODE", "disable")
  }
  # Dummy app is CI-only; Spring / bin/rails often boot `development` even when we intend `test`.
  # Mirror `test` so `db:migrate` never dies on missing `development` (see ActiveRecord::AdapterNotSpecified).
  database_yml = {
    "development" => test_db.dup,
    "test" => test_db.dup
  }

  config_file = File.expand_path("spec/decidim_dummy_app/config/database.yml", __dir__)
  File.open(config_file, "w") { |f| YAML.dump(database_yml, f) }
  Dir.chdir("spec/decidim_dummy_app") do
    # Strip Bundler’s parent-project env (`BUNDLE_GEMFILE`, etc. from `bundle exec rake` at engine root)
    # so `bundle exec` in the dummy app resolves that Gemfile. Use `with_unbundled_env`, not only
    # `with_original_env` (Bundler docs: subcommands in another directory).
    Bundler.with_unbundled_env do
      # Fresh DB every run: regenerating the dummy app rewrites migration timestamps, so an
      # existing schema (local compose volume / re-run) would hit PG::DuplicateTable.
      # Use Rake `sh` so a failed migrate aborts; `env` sets vars in the shell (reliable vs Kernel#system env quirks).
      sh "env RAILS_ENV=test DISABLE_SPRING=1 DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bundle exec rails db:drop db:create db:migrate"
    end
  end
end

desc "Generates a dummy app for testing"
task :test_app do
  Bundler.with_original_env do
    generate_decidim_app(
      "spec/decidim_dummy_app",
      "--app_name",
      "decidim_test",
      "--path",
      "../..",
      "--skip_spring",
      "--demo",
      "--force_ssl",
      "false",
      "--locales",
      "en,ca,es,fr"
    )
  end
  # Install under with_unbundled_env before install_module (needs `bundle exec rails`).
  Dir.chdir(File.expand_path("spec/decidim_dummy_app", __dir__)) do
    Bundler.with_unbundled_env do
      sh "bundle install -j $(nproc) --retry 3"
    end
  end
  install_module("spec/decidim_dummy_app")
  Rake::Task["prepare_tests"].invoke
end

desc "Generates a development app"
task :development_app do
  Bundler.with_original_env do
    generate_decidim_app(
      "development_app",
      "--app_name",
      "#{base_app_name}_development_app",
      "--path",
      "..",
      "--recreate_db",
      "--demo"
    )
  end
end
