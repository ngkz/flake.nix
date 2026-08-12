#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

flake=pin
downloads_url="https://www.intel.com/content/www/us/en/developer/articles/tool/pin-a-binary-instrumentation-tool-downloads.html"

# Extract the latest download URL from Intel downloads page
# Pattern: pin-external-{major}.{minor}-{build}-{commit}-gcc-linux.tar.gz
latest_url=$(curl -sfL "$downloads_url" |
    grep -oP 'href="https://software\.intel\.com/sites/landingpage/pintool/downloads/pin-external-[0-9.]+-[0-9]+-g[0-9a-f]+-gcc-linux\.tar\.gz"' |
    head -1 |
    sed 's/href="//;s/"$//')

if [[ -z "$latest_url" ]]; then
    echo "$flake: failed to extract download URL from $downloads_url"
    exit 1
fi

# Parse version and build number from URL
# Example: pin-external-4.3-99850-gce5652921-gcc-linux.tar.gz
url_basename=$(basename "$latest_url")
# Extract major.minor and build from the filename
version=$(echo "$url_basename" | sed 's/pin-external-\([0-9.]*\)-[0-9]*-.*/\1/')
build=$(echo "$url_basename" | sed 's/pin-external-[0-9.]*-\([0-9]*\)-.*/\1/')

current_version=$(nix eval --no-warn-dirty --raw "../..#${flake}.version")

if [[ "$current_version" == "$version" ]]; then
    echo "$flake is up-to-date: $version (build $build)"
    exit 0
fi

# Fetch to compute hash
new_hash=$(nix-prefetch-url "$latest_url" 2>&1 | tail -1)

if [[ -z "$new_hash" ]]; then
    echo "$flake: failed to prefetch $latest_url"
    exit 1
fi

# Update default.nix
sed -i "s/version = \".*\"/version = \"$version\"/" default.nix
sed -i "s|url = \".*\"|url = \"$latest_url\"|" default.nix
sed -i "s@\(sha256\).*@sha256 = \"$new_hash\";@" default.nix

echo "$flake updated: $current_version -> $version (build $build)"
