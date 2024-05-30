# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "blake3-rb"
  # Eventually, we would like to align with the upstream blake3 crate version,
  # so only ship patch-level changes in the gem version.
  spec.version = "1.5.4.1"
  spec.authors = ["Ian Ker-Seymer"]

  spec.summary = "Blake3 hash function bindings for Ruby."
  spec.description = "Provides native bindings to the Blake3 hash function for Ruby."
  spec.homepage = "https://github.com/Shopify/blake3-ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
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
  spec.extensions = ["ext/digest/blake3_ext/extconf.rb"]

  spec.add_dependency("rb_sys", "~> 0.9")
end
