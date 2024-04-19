# frozen_string_literal: true

require 'decidim/dev'

ENV['ENGINE_ROOT'] = File.dirname(__dir__)

Decidim::Dev.dummy_app_path = ENV.fetch('ROOT')

require 'decidim/dev/test/base_spec_helper'
