# frozen_string_literal: true

require_relative "lib/decidim_metabase/version"

Gem::Specification.new do |spec|
  spec.name          = "decidim_metabase"
  spec.version       = DecidimMetabase::VERSION
  spec.authors       = ["quentinchampenois"]
  spec.email         = ["26109239+Quentinchampenois@users.noreply.github.com"]

  spec.summary       = "Automatize the add of Decidim applications to your Metabase"
  spec.description   = "Allows to create easily Metabase collections and cards from your Decidim platform."
  spec.homepage      = "https://github.com/OpenSourcePolitics/decidim_metabase"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.7.1")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/OpenSourcePolitics/decidim_metabase"
  spec.metadata["changelog_uri"] = "https://github.com/OpenSourcePolitics/decidim_metabase/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
  spec.add_dependency "colorize"
  spec.add_dependency "dotenv"
  spec.add_dependency "faraday"
end
