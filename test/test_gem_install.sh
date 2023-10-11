#!/usr/bin/env bash

set -euxo pipefail

if [ "$1" == "precompiled" ]; then
  gem_platform="$(ruby -e 'puts [Gem::Platform.local.cpu, Gem::Platform.local.os].join("-")')"

  if [ "$gem_platform" == "x64-mingw" ]; then
    gem_platform="$(ruby -e 'puts RUBY_PLATFORM')"
  fi

  gem_pkg="$(ls pkg/*-$gem_platform.gem)"

  if [ -z "$gem_pkg" ]; then
    echo "ERROR: No precompiled gem found for $gem_platform"
    exit 1
  fi
else
  gem_pkg="$(ls $1)"
fi

gem install --verbose "$gem_pkg"

echo "Running tests..."

if ruby -rdigest/blake3 -e 'exit(Digest::Blake3.hexdigest("foo") == "04e0bb39f30b1a3feb89f536c93be15055482df748674b00d26e5a75777702e9")'; then
  echo "✅ Tests passed!"
else
  echo "❌ Tests failed!"
  exit 1
fi
