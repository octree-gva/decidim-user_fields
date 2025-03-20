# frozen_string_literal: true

source "https://rubygems.org"

base_path = "./"
base_path = "../../" if File.basename(__dir__) == "decidim_dummy_app"
base_path = "../" if File.basename(__dir__) == "development_app"

require_relative "#{base_path}lib/decidim/custom_user_fields/version"

DECIDIM_VERSION = "~> 0.29"

gem "decidim", DECIDIM_VERSION
gem "decidim-user_fields", path: base_path

gem "bootsnap", "~> 1.18"
gem "puma", ">= 6.6"
gem "uglifier", "~> 4.2"

gem "deface", ">= 1.9"

group :development, :test do
  gem "byebug", "~> 11.1", platform: :mri
  gem "decidim-dev", DECIDIM_VERSION
end

group :test do
  gem "capybara", "~> 3.40"
  gem "rspec-rails", "~> 6.0"
  gem "rubocop-faker"
  gem "selenium-webdriver"
end

group :development do
  gem "faker", "~> 3.5"
  gem "letter_opener_web", "~> 3.0"
  gem "listen", "~> 3.9"
  gem "web-console", "~> 4.2"
end
