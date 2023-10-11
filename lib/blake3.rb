# frozen_string_literal: true

require_relative "blake3/version"

# Tries to require the extension for the given Ruby version first
begin
  RUBY_VERSION =~ /(\d+\.\d+)/
  require "blake3/#{Regexp.last_match(1)}/blake3"
rescue LoadError
  require_relative "blake3/blake3"
end
