#!/usr/bin/env bash
# Update ghidra-rpc from the latest GitHub release.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

pname=ghidra-rpc
owner=cellebrite-labs
repo=ghidra-rpc

current=$(sed -n 's/^  version = "\([^"]*\)";/\1/p' default.nix)
latest_tag=$(gh api "repos/$owner/$repo/releases/latest" --jq '.tag_name')
latest=${latest_tag#v}

if [[ $current == "$latest" ]]; then
    echo "$pname is up-to-date: $latest"
    exit 0
fi

source_hash=$(nix-prefetch-github --json "$owner" "$repo" --rev "$latest_tag" | jq -r .hash)

sed -i "s/^  version = \".*\";/  version = \"$latest\";/" default.nix
sed -i "s@^    hash = \".*\";@    hash = \"$source_hash\";@" default.nix

echo "$pname updated: $current -> $latest"
