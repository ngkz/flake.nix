#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

pname=crosvm
url=$(sed -n 's/.*url = "\(.*\)";/\1/p' default.nix)

current_rev=$(sed -n 's/.*rev = "\(.*\)";/\1/p' default.nix)
latest_rev=$(git ls-remote "$url" HEAD | cut -f1)

if [[ $current_rev == "$latest_rev" ]]; then
    echo "$pname is up-to-date: $latest_rev"
    exit 0
fi

# Extract date from rev for version (use commit date)
commit_date=$(nix-prefetch-git --quiet --fetch-submodules "$url" "$latest_rev" 2>/dev/null | jq -r '.date' | cut -d'T' -f1)
new_version="0-unstable-${commit_date}"

sed -i "s|rev = \".*\"|rev = \"$latest_rev\"|" default.nix
sed -i "s|version = \".*\"|version = \"$new_version\"|" default.nix

newhash=$(nix-prefetch-git --quiet --fetch-submodules "$url" "$latest_rev" | jq -r .hash)
sed -i "s@hash = \".*\"@hash = \"$newhash\"@" default.nix

sed -i 's/cargoHash = ".*";/cargoHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";/' default.nix

out=$(nix build --no-link "../..#$pname" 2>&1 | sed -n "s/.*got:\s*\(.*\)/\1/p" || true)
sed -i "s@cargoHash = \".*\";@cargoHash = \"$out\";@" default.nix

echo "$pname updated: $current_rev -> $latest_rev ($new_version)"
