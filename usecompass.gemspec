# frozen_string_literal: true

require_relative "lib/usecompass/version"

Gem::Specification.new do |spec|
  spec.name = "usecompass"
  spec.version = Usecompass::VERSION
  spec.authors = ["Your Company"]
  spec.email = ["dev@yourcompany.com"]

  spec.summary = "A tool to guide your Rails usecase architecture"
  spec.description = "Usecompass helps maintain clean layered architecture by checking that controllers call usecases and usecases have corresponding specs"
  spec.homepage = "https://github.com/Akito-n/useCompass"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.4.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Dependencies
  spec.add_dependency "parser", "~> 3.0"
  spec.add_dependency "rainbow", "~> 3.0"
  
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 1.0"
end