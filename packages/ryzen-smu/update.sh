#!/usr/bin/env bash
# Update ryzen-smu from amkillam/ryzen_smu
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

owner=amkillam
repo=ryzen_smu

current_rev=$(sed -n 's/.*rev = "\(.*\)";.*/\1/p' default.nix)
latest_rev=$(gh api "repos/$owner/$repo/commits/main" --jq '.sha')

if [[ "$current_rev" == "$latest_rev" ]]; then
    echo "ryzen-smu is up-to-date: $latest_rev"
    exit 0
fi

newhash=$(nix-prefetch-github --json "$owner" "$repo" --rev "$latest_rev" | jq -r .hash)

upstream_version=$(gh api "repos/$owner/$repo/contents/Makefile" --jq '.content' | base64 -d | sed -n 's/^VERSION[[:space:]]*:=[[:space:]]*//p')
commit_date=$(gh api "repos/$owner/$repo/commits/$latest_rev" --jq '.commit.author.date' | cut -d'T' -f1)
sed -i "s|rev = \"$current_rev\"|rev = \"$latest_rev\"|" default.nix
sed -i "s|upstreamVersion = \"[^\"]*\"|upstreamVersion = \"$upstream_version\"|" default.nix
sed -i "s|version = \"\${upstreamVersion}-unstable-[^\"]*\"|version = \"\${upstreamVersion}-unstable-$commit_date\"|" default.nix
sed -i "s|hash = \"[^\"]*\"|hash = \"$newhash\"|" default.nix

echo "Updated rev: $current_rev -> $latest_rev"
