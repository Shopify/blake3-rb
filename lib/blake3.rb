# frozen_string_literal: true

if defined?(Blake3::Hasher)
  warn "WARNING: Both blake3 and blake3-ruby gems are installed, and may conflict with each other"
end

require_relative "blake3/version"

# Tries to require the precompiled extension for the given Ruby version first
begin
  RUBY_VERSION =~ /(\d+\.\d+)/
  require "blake3/#{Regexp.last_match(1)}/blake3"
rescue LoadError
  require_relative "blake3/blake3"
end

# module Blake3
#   class << self
#     # Returns the Blake3 digest for the given string, encoded in hex.
#     #
#     # @example
#     #   Blake3.hexdigest("hello world")
#     #
#     # @param str [String] the string to digest
#     # @return [String] the hex-encoded digest
#     def hexdigest(str)
#       Digest.new.update(str).hexdigest
#     end

#     # Returns the Blake3 digest for the given string, as raw bytes.
#     #
#     # @example
#     #   Blake3.digest("hello world")
#     #
#     # @param str [String] the string to digest
#     # @return [String] the raw digest
#     def digest(str)
#       Digest.new.update(str).digest
#     end

#     # Returns the Blake3 digest for the given string, encoded in base64.
#     #
#     # @example
#     #   Blake3.base64digest("hello world")
#     #
#     # @param str [String] the string to digest
#     # @return [String] the base64-encoded digest
#     def base64digest(str)
#       Digest.new.update(str).base64digest
#     end

#     # Returns the Blake3 digest for the given file.
#     #
#     # @example
#     #   Blake3.file("Gemfile.lock") # => #<Blake3: ...>
#     #
#     # @param path [String] the path to the file to digest
#     # @return [Blake3] digest for the given file
#     def file(path)
#       Digest.new.file(path)
#     end
#   end
# end
