#!/bin/sh

set -eu

# Finder-launched VS Code does not receive Homebrew's Ruby gem PATH. Flutter
# needs it to find CocoaPods before resolving iOS plugins.
PATH="/opt/homebrew/lib/ruby/gems/3.4.0/bin:/opt/homebrew/opt/ruby/bin:$PATH"
export PATH

project_dir=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
build_path="$project_dir/build"
build_target="/private/tmp/taxista-user-ios-build-$UID"

mkdir -p "$build_target"

if [ -L "$build_path" ]; then
  existing_target=$(readlink "$build_path")
  mkdir -p "$existing_target"
  /usr/bin/xattr -cr "$existing_target" 2>/dev/null || true
  exit 0
fi

if [ -e "$build_path" ]; then
  previous="$build_target.previous-$(date +%Y%m%d%H%M%S)"
  mv "$build_path" "$previous"
fi

ln -s "$build_target" "$build_path"
/usr/bin/xattr -cr "$build_target" 2>/dev/null || true
