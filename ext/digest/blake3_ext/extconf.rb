# frozen_string_literal: true

require "mkmf"
require "rb_sys/mkmf"

# Detect when DIGEST_USE_RB_EXT_RESOLVE_SYMBOL is defined truthy,
# which indicates rb_ext_resolve_symbol("digest.so", "rb_digest_wrap_metadata")
# will work with the version of Digest we're building against.
digest_use_rb_ext_resolve_symbol = try_compile(<<~C)
  #include <ruby/digest.h>

  #if !defined(DIGEST_USE_RB_EXT_RESOLVE_SYMBOL)
  # error DIGEST_USE_RB_EXT_RESOLVE_SYMBOL not defined
  #endif
  #if !DIGEST_USE_RB_EXT_RESOLVE_SYMBOL
  # error DIGEST_USE_RB_EXT_RESOLVE_SYMBOL is 0
  #endif
C
puts("digest_use_rb_ext_resolve_symbol=#{digest_use_rb_ext_resolve_symbol}")

create_rust_makefile("digest/blake3/blake3_ext") do |r|
  if digest_use_rb_ext_resolve_symbol
    r.extra_rustflags = ["--cfg digest_use_rb_ext_resolve_symbol"]
  end
end
