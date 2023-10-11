# frozen_string_literal: true

require "bundler/setup"
require "benchmark/ips"
require "digest"
require "blake3"

system("bundle exec rake compile:release") || abort("Failed to compile extension")

Benchmark.ips do |x|
  x.config(time: 5, warmup: 1)

  x.report("Digest::SHA1.file") do
    Digest::SHA1.file("Gemfile.lock")
  end

  x.report("Digest::SHA256.file") do
    Digest::SHA256.file("Gemfile.lock")
  end

  x.report("Digest::MD5.file") do
    Digest::MD5.file("Gemfile.lock")
  end

  x.report("Blake3::Digest.file") do
    Blake3::Digest.file("Gemfile.lock")
  end

  x.compare!
end
