require "bundler/setup"
require "benchmark/ips"
require "digest/sha2"
require "blake3"

system("bundle exec rake compile:release") || abort("Failed to compile extension")

INPUTS = [
  "hello world",
  "a much longer string that will still fit within a block",
  "a much longer string that exceeds one block " * 1024,
  "a" * 1024 * 1024,
]

Benchmark.ips do |x|
  x.config(time: 10, warmup: 1)

  x.report("Digest::SHA256") do
    INPUTS.each do |input|
      digest = Digest::SHA256.new
      digest << input
      digest.digest
    end
  end

  x.report("Blake3::Digest") do
    INPUTS.each do |input|
      digest = Blake3::Digest.new
      digest << input
      digest.digest
    end
  end

  x.compare!
end




