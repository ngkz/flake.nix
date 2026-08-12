#!/usr/bin/env bash
# Update the de4dot master revision and its NuGet dependency lockfile.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

pname=de4dot-kant2002
owner=kant2002
repo=de4dot
branch=master

current_rev=$(nix eval --no-warn-dirty --raw "../..#${pname}.src.rev")
current_version=$(nix eval --no-warn-dirty --raw "../..#${pname}.version")
commit=$(gh api "repos/$owner/$repo/commits/$branch")
latest_rev=$(jq -r .sha <<<"$commit")
latest_date=$(jq -r .commit.committer.date <<<"$commit" | cut -d'T' -f1)
latest_version=$(curl -sfL "https://raw.githubusercontent.com/$owner/$repo/$latest_rev/Directory.Build.props" |
    sed -n 's/.*<VersionPrefix>\([^<]*\)<\/VersionPrefix>.*/\1/p')

latest_version="${latest_version}-unstable-$latest_date"

if [[ "$current_rev" == "$latest_rev" ]]; then
    echo "$pname is up-to-date: $latest_version ($latest_rev)"
    exit 0
fi

new_hash=$(nix-prefetch-github --json "$owner" "$repo" --rev "$latest_rev" | jq -r .hash)
sed -i "s|rev = \".*\"|rev = \"$latest_rev\"|" default.nix
sed -i "s|hash = \".*\"|hash = \"$new_hash\"|" default.nix
sed -i "s/version = \".*\"/version = \"$latest_version\"/" default.nix

fetch_deps=$(nix build --no-link --print-out-paths "../..#${pname}.fetch-deps")
"$fetch_deps" "$PWD/deps.json"

echo "$pname updated: $current_version -> $latest_version"
