# frozen_string_literal: true

require "mkmf"

# Extension name
extension_name = "blake3_ext"

# Directory containing BLAKE3 C source files
blake3_dir = File.join(__dir__, "blake3")

# Detect architecture and platform
is_x86 = RbConfig::CONFIG["host_cpu"] =~ /x86_64|amd64|i[3-6]86/i
is_arm64 = RbConfig::CONFIG["host_cpu"] =~ /aarch64|arm64/i
is_arm32 = RbConfig::CONFIG["host_cpu"] =~ /arm/i && !is_arm64
is_windows = RbConfig::CONFIG["host_os"] =~ /mswin|mingw|cygwin/i

# Add BLAKE3 source directory to include path
$INCFLAGS << " -I#{blake3_dir}"

# Start with the core BLAKE3 source files
srcs = [
  "blake3/blake3.c",
  "blake3/blake3_dispatch.c",
  "blake3/blake3_portable.c",
]

# Add platform-specific SIMD implementations
# BLAKE3's blake3_dispatch.c handles runtime CPU feature detection automatically
if is_x86
  # x86/x86_64: Include ALL SIMD implementations
  # Runtime detection in blake3_dispatch.c will choose the best one
  srcs << "blake3/blake3_sse2.c"
  srcs << "blake3/blake3_sse41.c"
  srcs << "blake3/blake3_avx2.c"
  srcs << "blake3/blake3_avx512.c"
elsif is_arm64
  # AArch64: NEON is always available and enabled by default
  srcs << "blake3/blake3_neon.c"
elsif is_arm32
  # ARM32: Check for NEON support at compile time
  # NEON is optional on 32-bit ARM
  if have_macro("__ARM_NEON") || have_macro("__ARM_NEON__")
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

# On x86, we need to compile each SIMD file with appropriate flags
if is_x86
  $objs = $srcs.map { |f| File.basename(f, ".*") + ".o" }
end

# Create the Makefile
dir_config(extension_name)
create_makefile("digest/blake3/#{extension_name}")

# Append custom rules for SIMD compilation on x86
# Each SIMD implementation requires specific compiler flags to enable
# the corresponding instruction set, but runtime detection chooses which to use
if is_x86
  makefile = File.read("Makefile")

  simd_rules = <<~RULES

    # SIMD-specific compilation rules
    # Each file is compiled with flags to enable that instruction set
    # Runtime detection in blake3_dispatch.c selects the best implementation
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
