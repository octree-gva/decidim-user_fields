# frozen_string_literal: true

require "decidim/gem_manager"

namespace :decidim_custom_user_fields do
  namespace :webpacker do
    desc "Installs Custom User Fields webpacker files in Rails instance application"
    task install: :environment do
      raise "Decidim gem is not installed" if decidim_path.nil?

      install_custom_user_fields_npm
    end

    desc "Adds Custom User Fields dependencies in package.json"
    task upgrade: :environment do
      raise "Decidim gem is not installed" if decidim_path.nil?

      install_custom_user_fields_npm
    end

    def install_custom_user_fields_npm
      return if custom_user_fields_npm_dependencies.empty?

      puts "install NPM packages. You can also do this manually with this command:"
      puts "npm i #{custom_user_fields_npm_dependencies.join(" ")}"
      custom_user_fields_system! "npm i #{custom_user_fields_npm_dependencies.join(" ")}"
    end

    def custom_user_fields_npm_dependencies
      @custom_user_fields_npm_dependencies ||= if custom_user_fields_path.nil? || !File.exist?(custom_user_fields_path.join("package.json"))
                                                 []
                                               else
                                                 package_json = JSON.parse(File.read(custom_user_fields_path.join("package.json")))

                                                 (package_json["dependencies"] || {}).map { |package, version| "#{package}@#{version}" }
                                               end
    end

    def custom_user_fields_path
      @custom_user_fields_path ||= Pathname.new(custom_user_fields_gemspec.full_gem_path) if Gem.loaded_specs.has_key?(custom_user_fields_gem_name)
    end

    def rails_app_path
      @rails_app_path ||= Rails.root
    end

    def custom_user_fields_system!(command)
      system("cd #{rails_app_path} && #{command}") || abort("\n== Command #{command} failed ==")
    end

    def custom_user_fields_gemspec
      @custom_user_fields_gemspec ||= Gem.loaded_specs[custom_user_fields_gem_name]
    end

    def custom_user_fields_gem_name
      "decidim-user_fields"
    end
  end
end
