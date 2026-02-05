#!/usr/bin/env ruby
# frozen_string_literal: true

# Benchmark comparing C extension (this branch) vs Rust extension (released gem)
#
# This script runs each implementation in a separate process to avoid conflicts.
#
# Prerequisites:
#   1. Build the C extension: bundle exec rake compile
#   2. Install the Rust gem: gem install blake3-rb -v 1.5.5.0 --install-dir ./benchmark/rust_gem
#
# Usage:
#   ruby benchmark/run_comparison.rb

require "benchmark"
require "fileutils"

BENCHMARK_DIR = File.expand_path(__dir__)
PROJECT_ROOT = File.expand_path("..", BENCHMARK_DIR)
RUST_GEM_DIR = File.join(BENCHMARK_DIR, "rust_gem", "gems", "blake3-rb-1.5.5.0")
RUST_GEM_VERSION = "1.5.5.0"
RUBY_ABI_VERSION = RUBY_VERSION.split(".")[0..1].join(".")

# Data sizes to test
DATA_SIZES = {
  "13 bytes" => 13,
  "1 KB" => 1024,
  "10 KB" => 10 * 1024,
  "100 KB" => 100 * 1024,
  "1 MB" => 1024 * 1024,
  "10 MB" => 10 * 1024 * 1024,
}

ITERATIONS = {
  "13 bytes" => 100_000,
  "1 KB" => 50_000,
  "10 KB" => 10_000,
  "100 KB" => 1_000,
  "1 MB" => 100,
  "10 MB" => 10,
}

def check_rust_gem
  ext_path = File.join(RUST_GEM_DIR, "lib", "digest", "blake3", RUBY_ABI_VERSION, "blake3_ext.bundle")
  ext_path_so = File.join(RUST_GEM_DIR, "lib", "digest", "blake3", RUBY_ABI_VERSION, "blake3_ext.so")
  
  if File.exist?(ext_path) || File.exist?(ext_path_so)
    puts "Found Rust gem at #{RUST_GEM_DIR}"
    return true
  end
  
  puts "Rust gem not found at #{RUST_GEM_DIR}"
  puts "To set up the Rust gem for comparison:"
  puts "  cd benchmark/rust_gem"
  puts "  curl -sL 'https://rubygems.org/downloads/blake3-rb-1.5.5.0-arm64-darwin.gem' -o blake3-rb.gem"
  puts "  tar -xf blake3-rb.gem"
  puts "  mkdir -p gems/blake3-rb-1.5.5.0 && cd gems/blake3-rb-1.5.5.0"
  puts "  tar -xzf ../../data.tar.gz"
  false
end

def check_c_extension
  # Check if C extension is compiled
  ext_path = Dir.glob(File.join(PROJECT_ROOT, "lib", "digest", "blake3", "blake3_ext.{bundle,so,dll}")).first
  return true if ext_path && File.exist?(ext_path)
  
  puts "C extension not compiled. Running: bundle exec rake compile"
  Dir.chdir(PROJECT_ROOT) do
    system("bundle", "exec", "rake", "compile", exception: true)
  end
  true
rescue => e
  puts "Failed to compile C extension: #{e.message}"
  false
end

def benchmark_script(impl_type, data_size, iterations)
  <<~RUBY
    require "benchmark"
    
    #{impl_type == :rust ? rust_require_code : c_require_code}
    
    data = "x" * #{data_size}
    
    # Warmup
    10.times { Digest::Blake3.hexdigest(data) }
    
    # Benchmark
    time = Benchmark.realtime do
      #{iterations}.times { Digest::Blake3.hexdigest(data) }
    end
    
    # Output: total_time,iterations,data_size
    puts [time, #{iterations}, #{data_size}].join(",")
  RUBY
end

def rust_require_code
  <<~RUBY
    $LOAD_PATH.unshift("#{RUST_GEM_DIR}/lib")
    ENV["BUNDLE_GEMFILE"] = nil  # Disable bundler
    require "digest/blake3"
  RUBY
end

def c_require_code
  <<~RUBY
    $LOAD_PATH.unshift("#{PROJECT_ROOT}/lib")
    require "digest/blake3"
  RUBY
end

def run_benchmark(impl_type, data_size, iterations)
  script = benchmark_script(impl_type, data_size, iterations)
  
  output = IO.popen(["ruby", "-e", script], &:read)
  return nil unless $?.success?
  
  time, iters, size = output.strip.split(",").map(&:to_f)
  {
    time: time,
    iterations: iters.to_i,
    data_size: size.to_i,
    ops_per_sec: iters / time,
    throughput_mb_s: (size * iters) / time / (1024 * 1024)
  }
end

def format_number(n)
  n.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
end

# Main
puts "=" * 70
puts "BLAKE3 Benchmark: C Extension vs Rust Extension"
puts "=" * 70
puts ""

has_rust = check_rust_gem
has_c = check_c_extension

unless has_c
  abort "ERROR: Could not compile C extension"
end

puts ""
puts "Ruby version: #{RUBY_VERSION}"
puts "Platform: #{RUBY_PLATFORM}"
puts ""

# Verify correctness
puts "Verifying correctness..."
c_result = IO.popen(["ruby", "-e", <<~RUBY], &:read).strip
  $LOAD_PATH.unshift("#{PROJECT_ROOT}/lib")
  require "digest/blake3"
  puts Digest::Blake3.hexdigest("")
RUBY

expected = "af1349b9f5f9a1a6a0404dea36dcc9499bcb25c9adc112b7cc9a93cae41f3262"
if c_result != expected
  abort "ERROR: C extension produces wrong hash!\nExpected: #{expected}\nGot: #{c_result}"
end
puts "  C extension: OK"

if has_rust
  rust_result = IO.popen(["ruby", "-e", <<~RUBY], &:read).strip
    $LOAD_PATH.unshift("#{RUST_GEM_DIR}/lib")
    ENV["BUNDLE_GEMFILE"] = nil
    require "digest/blake3"
    puts Digest::Blake3.hexdigest("")
  RUBY
  
  if rust_result != expected
    abort "ERROR: Rust extension produces wrong hash!\nExpected: #{expected}\nGot: #{rust_result}"
  end
  puts "  Rust extension: OK"
end

puts ""
puts "-" * 70
puts "Running benchmarks..."
puts "-" * 70
puts ""

results = {}

DATA_SIZES.each do |label, size|
  iterations = ITERATIONS[label]
  
  print "Benchmarking #{label}... "
  
  c_result = run_benchmark(:c, size, iterations)
  rust_result = has_rust ? run_benchmark(:rust, size, iterations) : nil
  
  results[label] = { c: c_result, rust: rust_result }
  puts "done"
end

puts ""
puts "=" * 70
puts "Results"
puts "=" * 70
puts ""

# Print results table
if has_rust
  puts "%-12s | %15s | %15s | %10s" % ["Data Size", "C (ops/sec)", "Rust (ops/sec)", "C vs Rust"]
  puts "-" * 70
  
  results.each do |label, data|
    c_ops = data[:c][:ops_per_sec]
    rust_ops = data[:rust][:ops_per_sec]
    ratio = c_ops / rust_ops
    ratio_str = ratio >= 1 ? "#{ratio.round(2)}x faster" : "#{(1/ratio).round(2)}x slower"
    
    puts "%-12s | %15s | %15s | %10s" % [
      label,
      format_number(c_ops.round(0)),
      format_number(rust_ops.round(0)),
      ratio_str
    ]
  end
else
  puts "%-12s | %15s | %15s" % ["Data Size", "C (ops/sec)", "Throughput"]
  puts "-" * 56
  
  results.each do |label, data|
    c_ops = data[:c][:ops_per_sec]
    throughput = data[:c][:throughput_mb_s]
    
    puts "%-12s | %15s | %12.2f MB/s" % [
      label,
      format_number(c_ops.round(0)),
      throughput
    ]
  end
end

puts ""
puts "=" * 70
puts "Throughput Comparison"
puts "=" * 70
puts ""

if has_rust
  puts "%-12s | %12s | %12s | %10s" % ["Data Size", "C (MB/s)", "Rust (MB/s)", "C vs Rust"]
  puts "-" * 56
  
  results.each do |label, data|
    c_tp = data[:c][:throughput_mb_s]
    rust_tp = data[:rust][:throughput_mb_s]
    ratio = c_tp / rust_tp
    ratio_str = ratio >= 1 ? "#{ratio.round(2)}x" : "#{(1/ratio).round(2)}x slower"
    
    puts "%-12s | %12.2f | %12.2f | %10s" % [label, c_tp, rust_tp, ratio_str]
  end
else
  puts "(Rust gem not available for comparison)"
end

puts ""
