#!/usr/bin/env bash
# Update the KLEE version and source hash.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

pname=klee
owner=klee
repo=klee

current_version=$(nix eval --no-warn-dirty --raw "../..#${pname}.version")
latest_tag=$(gh api "repos/$owner/$repo/releases/latest" --jq '.tag_name')
latest_version=${latest_tag#v}

if [[ "$current_version" == "$latest_version" ]]; then
    echo "$pname is up-to-date: $latest_version"
    exit 0
fi

new_hash=$(nix-prefetch-github --json "$owner" "$repo" --rev "$latest_tag" | jq -r .hash)
sed -i "s/version = \".*\"/version = \"$latest_version\"/" default.nix
sed -i "s@hash = \".*\"@hash = \"$new_hash\"@" default.nix

echo "$pname updated: $current_version -> $latest_version"
