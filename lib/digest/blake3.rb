# frozen_string_literal: true

require "digest"

module Digest
  class Blake3 < Digest::Base
  end
end

require_relative "blake3/version"
require_relative "blake3/blake3_ext"
