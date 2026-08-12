#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

owner=DynamoRIO
repo=dynamorio
pname=dynamorio
current=$(sed -n 's/.*version = "\(.*\)";.*/\1/p' default.nix)
latest_tag=$(gh api "repos/$owner/$repo/releases/latest" --jq '.tag_name')
latest=${latest_tag#cronbuild-}

if [[ "$latest_tag" == "$latest" ]]; then
    echo "$pname: unsupported release tag: $latest_tag"
    exit 1
fi

if [[ "$current" == "$latest" ]]; then
    echo "$pname is up-to-date: $latest"
    exit 0
fi

new_hash=$(nix-prefetch-github --json --fetch-submodules "$owner" "$repo" --rev "$latest_tag" | jq -r .hash)
sed -i "s/version = \"$current\"/version = \"$latest\"/" default.nix
sed -i "s|hash = \".*\"|hash = \"$new_hash\"|" default.nix

echo "$pname updated: $current -> $latest"
