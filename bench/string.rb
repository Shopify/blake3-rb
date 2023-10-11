# frozen_string_literal: true

require "bundler/setup"
require "benchmark/ips"
require "digest"
require "blake3"

system("bundle exec rake compile:release") || abort("Failed to compile extension")

INPUTS = [
  "hello world",
  "a much longer string that will still fit within a block",
  "a much longer string that exceeds one block " * 1024,
  "a" * 1024 * 1024,
]

Benchmark.ips do |x|
  x.config(time: 5, warmup: 1)

  x.report("Digest::SHA1") do
    INPUTS.each do |input|
      digest = Digest::SHA1.new
      digest << input
      digest.digest
    end
  end

  x.report("Digest::SHA256") do
    INPUTS.each do |input|
      digest = Digest::SHA256.new
      digest << input
      digest.digest
    end
  end

  x.report("Digest::MD5") do
    INPUTS.each do |input|
      digest = Digest::MD5.new
      digest << input
      digest.digest
    end
  end

  x.report("Blake3::Digest") do
    INPUTS.each do |input|
      digest = Digest::Blake3.new
      digest << input
      digest.digest
    end
  end

  x.compare!
end
