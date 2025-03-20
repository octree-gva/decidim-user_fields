# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("lib", __dir__)

require "decidim/custom_user_fields/version"

Gem::Specification.new do |s|
  s.version = Decidim::CustomUserFields.version
  s.authors = ["Hadrien Froger"]
  s.email = ["hadrien@octree.ch"]
  s.license = "AGPL-3.0"
  s.homepage = "https://git.octree.ch/decidim/decidim-user_fields"
  s.required_ruby_version = ">= 3.2"

  s.name = "decidim-user_fields"
  s.summary = "Configure user fields for your decidim users"
  s.description = "Allows to collect and manage some extra user fields on registration and profile edition."

  s.files = Dir["{app,config,lib}/**/*", "LICENSE-AGPLv3.txt", "Rakefile", "README.md"]

  s.add_dependency "decidim-core", Decidim::CustomUserFields.decidim_version
  s.add_dependency "decidim-verifications", Decidim::CustomUserFields.decidim_version
  s.add_dependency "deface", ">= 1.9"

  s.metadata["rubygems_mfa_required"] = "true"
end
