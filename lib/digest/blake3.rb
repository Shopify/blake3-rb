# frozen_string_literal: true

require "digest"

module Digest
  class Blake3 < Digest::Base
  end
end

require_relative "blake3/version"

# Try to load precompiled binary for current Ruby version, fall back to source extension
begin
  ruby_version = /(\d+\.\d+)/.match(::RUBY_VERSION)
  require_relative "blake3/#{ruby_version}/blake3_ext"
rescue LoadError
  require_relative "blake3/blake3_ext"
end
