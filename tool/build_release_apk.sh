#!/bin/sh
# Release APK for testers and the store, always against production:
#
#   tool/build_release_apk.sh            (version and build number from pubspec.yaml)
#
# Builds only from a committed tree, passes the production API itself, then
# reads the API address compiled into the APK and refuses anything else: rider
# APK 6.5.0+39 (2026-11-01) was built without API_BASE_URL, pointed at
# 127.0.0.1 and nobody could sign in. Prints the commit, version and checksum.

set -eu

api=https://taxista.aljidartech.com/
project_dir=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
cd "$project_dir"

if [ -n "$(git status --porcelain)" ]; then
  echo "Uncommitted changes: commit first, so the APK maps to exactly one commit." >&2
  exit 1
fi
commit=$(git rev-parse --short HEAD)
branch=$(git rev-parse --abbrev-ref HEAD)
version=$(sed -n 's/^version: *//p' pubspec.yaml)
name=${version%%+*}
number=${version##*+}

flutter build apk --release --build-name="$name" --build-number="$number" \
  --dart-define=API_BASE_URL="$api"

apk=build/app/outputs/flutter-apk/app-release.apk
check=$(mktemp -d)
unzip -q -o "$apk" 'lib/arm64-v8a/libapp.so' -d "$check"
found=$(strings "$check/lib/arm64-v8a/libapp.so" |
  grep -E '^https?://(127\.0\.0\.1|10\.0\.2\.2|localhost|[a-z0-9.-]*taxista[a-z0-9.-]*)[:/0-9]*/?$' |
  sort -u | tr '\n' ' ' | sed 's/ $//')
rm -rf "$check"
if [ "$found" != "$api" ]; then
  echo "REFUSED: the APK must call $api only; it contains: ${found:-nothing}" >&2
  exit 1
fi

out="$HOME/Downloads/Taxista-APK-$(date +%Y-%m-%d)"
mkdir -p "$out"
target="$out/TaxistaRider-$name-build$number-$commit.apk"
cp "$apk" "$target"
echo "API      $found"
echo "branch   $branch"
echo "commit   $commit"
echo "version  $name ($number)"
echo "apk      $target"
echo "sha256   $(shasum -a 256 "$target" | cut -d' ' -f1)"
