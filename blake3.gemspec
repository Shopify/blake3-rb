# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "digest-blake3"
  spec.version = "0.1.0"
  spec.authors = ["Ian Ker-Seymer"]
  spec.email = ["ian.kerseymer@shopify.com"]

  spec.summary = "Blake3 hash function bindings for Ruby."
  spec.description = "Provides native bindings to the Blake3 hash function for Ruby."
  spec.homepage = "https://github.com/Shopify/blake3-ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  # spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  spec.files = Dir[
    "lib/**/*.rb",
    "exe/**/*",
    "ext/**/*.{rs,rb,toml}",
    "**/Cargo.{toml,lock}",
    "README.md",
    "LICENSE.txt"
  ]
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.extensions = ["ext/blake3/extconf.rb"]

  spec.add_dependency("rb_sys", "~> 0.9")
end
