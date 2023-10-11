# Blake3 Ruby Gem

![Gem Version](https://badge.fury.io/rb/blake3.svg)]
![Build Status](https://github.com/Shopify/blake3-ruby/workflows/CI/badge.svg)

Blake3 is a Ruby gem that provides a simple and efficient way to compute the Blake3 cryptographic hash function. This gem is designed to be easy to use and integrate into your Ruby projects.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'blake3'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install blake3
```

## Usage

Here's a simple usage example:

```ruby
require 'blake3'

result = Blake3.hexdigest("your data here")
```

If you need to stream data:

```ruby
require 'blake3'

hasher = Blake3::Digest.new
hasher.update("your data here")
result = hasher.hexdigest
```

Or use the `<<` operator:

```ruby
hasher = Blake3::Digest.new
hasher << "part1" << "part2"
result = hasher.hexdigest
```

### Base64 Digest

You can compute the Base64 digest of your data:

```ruby
result = Blake3.base64digest("your data here")
```

### Equality

You can compare two digests for equality:

```ruby
digest_one = Blake3::Digest.new
digest_two = Blake3::Digest.new

digest_one.update("your data here")
digest_two.update("your data here")

if digest_one == digest_two
  puts "Digests are equal"
else
  puts "Digests are not equal"
end
```

You can also compare a digest with a string:

```ruby
digest = Blake3::Digest.new
digest.update("your data here")

if digest == "your expected hash here"
  puts "Digest matches the expected hash"
else
  puts "Digest does not match the expected hash"
end
```

You can compute the hash of a file:

```ruby
result = Blake3.file("path/to/your/file")
```

You can clone the hasher's state:

```ruby
hasher = Blake3::Digest.new
hasher.update("part1")
cloned_hasher = hasher.new
cloned_hasher << "part2" # original hasher is not affected
```

You can reset the hasher's state:

```ruby
hasher = Blake3::Digest.new
hasher.update("part1")
hasher.reset
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
      Blake3::Digest   560.000  i/100ms
Calculating -------------------------------------
        Digest::SHA1    612.174  (± 0.3%) i/s -      3.111k in   5.081922s
      Digest::SHA256    215.281  (± 0.0%) i/s -      1.092k in   5.072453s
         Digest::MD5    586.009  (± 0.3%) i/s -      2.958k in   5.047759s
      Blake3::Digest      5.698k (± 0.6%) i/s -     28.560k in   5.012308s

Comparison:
      Blake3::Digest:     5698.2 i/s
        Digest::SHA1:      612.2 i/s - 9.31x  slower
         Digest::MD5:      586.0 i/s - 9.72x  slower
      Digest::SHA256:      215.3 i/s - 26.47x  slower

```

## Testing

First, make sure your development environment is setup:

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
