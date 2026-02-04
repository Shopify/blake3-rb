# frozen_string_literal: true

require "mkmf"

# Extension name
extension_name = "blake3_ext"

# Directory containing BLAKE3 C source files
blake3_dir = File.join(__dir__, "blake3")

# Detect architecture and platform
is_x86_64 = RbConfig::CONFIG["host_cpu"] =~ /x86_64|amd64/i
is_x86_32 = RbConfig::CONFIG["host_cpu"] =~ /i[3-6]86/i
is_arm64 = RbConfig::CONFIG["host_cpu"] =~ /aarch64|arm64/i
is_arm32 = RbConfig::CONFIG["host_cpu"] =~ /arm/i && !is_arm64
is_windows = RbConfig::CONFIG["host_os"] =~ /mswin|mingw|cygwin/i
RbConfig::CONFIG["host_os"] =~ /darwin/i

# Add BLAKE3 source directory to include path
$INCFLAGS << " -I#{blake3_dir}"

# Start with the core BLAKE3 source files
srcs = [
  "blake3/blake3.c",
  "blake3/blake3_dispatch.c",
  "blake3/blake3_portable.c",
]

# Add platform-specific SIMD implementations
if is_x86_64 || is_x86_32
  # x86/x86_64: Use intrinsics-based implementations
  # We compile each SIMD file separately with appropriate flags

  # SSE2 support (baseline for x86_64)
  if arg_config("--disable-sse2")
    $CFLAGS << " -DBLAKE3_NO_SSE2"
  else
    srcs << "blake3/blake3_sse2.c"
  end

  # SSE4.1 support
  if arg_config("--disable-sse41")
    $CFLAGS << " -DBLAKE3_NO_SSE41"
  else
    srcs << "blake3/blake3_sse41.c"
  end

  # AVX2 support
  if arg_config("--disable-avx2")
    $CFLAGS << " -DBLAKE3_NO_AVX2"
  else
    srcs << "blake3/blake3_avx2.c"
  end

  # AVX512 support
  if arg_config("--disable-avx512")
    $CFLAGS << " -DBLAKE3_NO_AVX512"
  else
    srcs << "blake3/blake3_avx512.c"
  end
elsif is_arm64
  # AArch64: NEON is enabled by default
  srcs << "blake3/blake3_neon.c"
elsif is_arm32
  # ARM32: NEON support must be explicitly enabled
  if arg_config("--enable-neon")
    srcs << "blake3/blake3_neon.c"
    $CFLAGS << " -DBLAKE3_USE_NEON=1"
  end
end

# Set source files (relative to ext directory)
$srcs = ["blake3_ext.c"] + srcs
$VPATH << "$(srcdir)/blake3"

# Add optimization flags
$CFLAGS << " -O3"

# Enable position-independent code for shared library
$CFLAGS << " -fPIC" unless is_windows

# On x86/x86_64, we need to set compiler flags for each SIMD implementation
# This is handled via separate rules in the Makefile
if is_x86_64 || is_x86_32
  # Create custom compilation rules for SIMD files
  $objs = $srcs.map { |f| File.basename(f, ".*") + ".o" }
end

# Create the Makefile
dir_config(extension_name)
create_makefile("digest/blake3/#{extension_name}")

# Append custom rules for SIMD compilation on x86
if is_x86_64 || is_x86_32
  makefile = File.read("Makefile")

  simd_rules = <<~RULES

    # SIMD-specific compilation rules
    blake3_sse2.o: $(srcdir)/blake3/blake3_sse2.c
    \t$(ECHO) compiling $(<)
    \t$(Q) $(CC) $(INCFLAGS) $(CPPFLAGS) $(CFLAGS) -msse2 -c -o $@ $<

    blake3_sse41.o: $(srcdir)/blake3/blake3_sse41.c
    \t$(ECHO) compiling $(<)
    \t$(Q) $(CC) $(INCFLAGS) $(CPPFLAGS) $(CFLAGS) -msse4.1 -c -o $@ $<

    blake3_avx2.o: $(srcdir)/blake3/blake3_avx2.c
    \t$(ECHO) compiling $(<)
    \t$(Q) $(CC) $(INCFLAGS) $(CPPFLAGS) $(CFLAGS) -mavx2 -c -o $@ $<

    blake3_avx512.o: $(srcdir)/blake3/blake3_avx512.c
    \t$(ECHO) compiling $(<)
    \t$(Q) $(CC) $(INCFLAGS) $(CPPFLAGS) $(CFLAGS) -mavx512f -mavx512vl -c -o $@ $<

  RULES

  File.write("Makefile", makefile + simd_rules)
end
