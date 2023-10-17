# frozen_string_literal: true

require "digest"

module Digest
  class Blake3 < Digest::Base
  end
end

# Tries to require the precompiled extension for the given Ruby version first
begin
  RUBY_VERSION =~ /(\d+\.\d+)/
  require "digest/blake3/#{Regexp.last_match(1)}/blake3_ext"
rescue LoadError
  require_relative "blake3/blake3_ext"
end
