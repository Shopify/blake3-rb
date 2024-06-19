# `blake3-rb`

[![Gem Version](https://badge.fury.io/rb/blake3-rb.svg)](https://badge.fury.io/rb/blake3-rb)
![Build Status](https://github.com/Shopify/blake3-ruby/workflows/CI/badge.svg)

Blake3 is a Ruby gem that provides a simple and efficient way to compute the Blake3 cryptographic hash function. This gem is designed to be easy to use and integrate into your Ruby projects using the Ruby [`digest` framework](https://github.com/ruby/digest).

## Installation

Add this line to your application's Gemfile:

```ruby
gem "blake3-rb"
```

We provide pre-built binaries for most common platforms. This is the preferred way to install this gem since it will be faster and more reliable than compiling from source. Make sure Bundler is configured to use the pre-built binaries by running:

```bash
bundle lock --add-platform x86_64-linux
bundle install    # resolve dependencies for platform-specific gems
```

## Usage

Here's a simple usage example:

```ruby
require "digest/blake3"

result = Digest::Blake3.hexdigest("your data here")
```

If you need to stream data:

```ruby
require "digest/blake3"

hasher = Digest::Blake3.new
hasher.update("your data here")
result = hasher.hexdigest
```

Or use the `<<` operator:

```ruby
require "digest/blake3"

hasher = Digest::Blake3.new
hasher << "part1" << "part2"
result = hasher.hexdigest
```

### Base64 Digest

You can compute the Base64 digest of your data:

```ruby
require "digest/blake3"

result = Digest::Blake3.base64digest("your data here")
```

### Equality

You can compare two digests for equality:

```ruby
require "digest/blake3"

digest_one = Digest::Blake3.new
digest_two = Digest::Blake3.new

digest_one.update("your data here")
digest_two.update("your data here")

if digest_one == digest_two
  puts "Digests are equal"
else
  puts "Digests are not equal"
end
```

You can compute the hash of a file:

```ruby
require "digest/blake3"

result = Digest::Blake3.file("path/to/your/file")
```

## Benchmarks

Here are some benchmarks comparing this gem with other digests on `x86_64-linux`:

```bash
$ ruby bench/string.rb
...
Warming up --------------------------------------
        Digest::SHA1    61.000  i/100ms
      Digest::SHA256    21.000  i/100ms
         Digest::MD5    58.000  i/100ms
      Digest::Blake3   560.000  i/100ms
Calculating -------------------------------------
        Digest::SHA1    612.174  (± 0.3%) i/s -      3.111k in   5.081922s
      Digest::SHA256    215.281  (± 0.0%) i/s -      1.092k in   5.072453s
         Digest::MD5    586.009  (± 0.3%) i/s -      2.958k in   5.047759s
      Digest::Blake3      5.698k (± 0.6%) i/s -     28.560k in   5.012308s

Comparison:
      Digest::Blake3:     5698.2 i/s
        Digest::SHA1:      612.2 i/s - 9.31x  slower
         Digest::MD5:      586.0 i/s - 9.72x  slower
      Digest::SHA256:      215.3 i/s - 26.47x  slower

```

## Testing

First, make sure your development environment is set up:

```bash
$ bin/setup
```

To run the tests, execute:

```bash
$ bundle exec rake test
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Shopify/blake3-ruby. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/Shopify/blake3-ruby/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Blake3 project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/Shopify/blake3-ruby/blob/main/CODE_OF_CONDUCT.md).
