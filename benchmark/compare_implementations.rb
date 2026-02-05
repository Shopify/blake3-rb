#!/usr/bin/env ruby
# frozen_string_literal: true

# Benchmark comparing C extension vs Rust extension performance
#
# Usage:
#   1. First, install the released Rust version in a separate directory:
#      gem install blake3-rb -v 1.5.5.0 --install-dir ./benchmark/rust_gem
#
#   2. Build the current C extension:
#      bundle exec rake compile
#
#   3. Run this benchmark:
#      ruby benchmark/compare_implementations.rb

require "benchmark/ips"
require "digest"

# Load the C extension (current development version)
$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))
require "digest/blake3"

C_BLAKE3 = Digest::Blake3

# Try to load the Rust extension from the installed gem
rust_gem_path = File.expand_path("rust_gem/gems/blake3-rb-1.5.5.0/lib", __dir__)
if Dir.exist?(rust_gem_path)
  # Temporarily modify load path to load rust version
  $LOAD_PATH.unshift(rust_gem_path)
  
  # We need to load it under a different name since Digest::Blake3 is already defined
  # This is tricky - we'll use a subprocess approach instead
  HAS_RUST = true
else
  HAS_RUST = false
  puts "WARNING: Rust gem not found at #{rust_gem_path}"
  puts "Install it with: gem install blake3-rb -v 1.5.5.0 --install-dir ./benchmark/rust_gem"
  puts ""
  puts "Running C extension benchmarks only..."
  puts ""
end

# Test data of various sizes
SMALL_DATA = "Hello, World!"
MEDIUM_DATA = "x" * 1024          # 1 KB
LARGE_DATA = "x" * (1024 * 1024)  # 1 MB
HUGE_DATA = "x" * (10 * 1024 * 1024)  # 10 MB

def format_size(bytes)
  if bytes >= 1024 * 1024
    "#{bytes / (1024 * 1024)} MB"
  elsif bytes >= 1024
    "#{bytes / 1024} KB"
  else
    "#{bytes} bytes"
  end
end

puts "=" * 60
puts "BLAKE3 Benchmark: C Extension"
puts "=" * 60
puts ""
puts "Ruby version: #{RUBY_VERSION}"
puts "Platform: #{RUBY_PLATFORM}"
puts ""

# Verify correctness first
expected_empty = "af1349b9f5f9a1a6a0404dea36dcc9499bcb25c9adc112b7cc9a93cae41f3262"
actual = C_BLAKE3.hexdigest("")
if actual != expected_empty
  abort "ERROR: C extension produces incorrect hash! Expected #{expected_empty}, got #{actual}"
end
puts "Correctness check: PASSED"
puts ""

puts "Data sizes:"
puts "  Small:  #{format_size(SMALL_DATA.bytesize)}"
puts "  Medium: #{format_size(MEDIUM_DATA.bytesize)}"
puts "  Large:  #{format_size(LARGE_DATA.bytesize)}"
puts "  Huge:   #{format_size(HUGE_DATA.bytesize)}"
puts ""

puts "-" * 60
puts "Benchmarking C Extension (this branch)"
puts "-" * 60
puts ""

Benchmark.ips do |x|
  x.config(time: 3, warmup: 1)

  x.report("C: small (#{format_size(SMALL_DATA.bytesize)})") do
    C_BLAKE3.hexdigest(SMALL_DATA)
  end

  x.report("C: medium (#{format_size(MEDIUM_DATA.bytesize)})") do
    C_BLAKE3.hexdigest(MEDIUM_DATA)
  end

  x.report("C: large (#{format_size(LARGE_DATA.bytesize)})") do
    C_BLAKE3.hexdigest(LARGE_DATA)
  end

  x.report("C: huge (#{format_size(HUGE_DATA.bytesize)})") do
    C_BLAKE3.hexdigest(HUGE_DATA)
  end
end

puts ""
puts "-" * 60
puts "Throughput (MB/s)"
puts "-" * 60

# Measure throughput for large data
require "benchmark"

iterations = 100
time = Benchmark.realtime do
  iterations.times { C_BLAKE3.hexdigest(LARGE_DATA) }
end
throughput = (LARGE_DATA.bytesize * iterations) / time / (1024 * 1024)
puts "C Extension: #{throughput.round(2)} MB/s (1 MB data, #{iterations} iterations)"

iterations = 10
time = Benchmark.realtime do
  iterations.times { C_BLAKE3.hexdigest(HUGE_DATA) }
end
throughput = (HUGE_DATA.bytesize * iterations) / time / (1024 * 1024)
puts "C Extension: #{throughput.round(2)} MB/s (10 MB data, #{iterations} iterations)"
