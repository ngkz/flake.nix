#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

pname=e9patch
owner=GJDuck
repo=e9patch

current=$(sed -n 's/.*version = "\(.*\)";.*/\1/p' default.nix)
latest_tag=$(gh api "repos/$owner/$repo/releases/latest" --jq '.tag_name')
latest=${latest_tag#v}

if [[ $current == "$latest" ]]; then
    echo "$pname is up-to-date: $latest"
    exit 0
fi

sed -i "s/version = \"$current\"/version = \"$latest\"/" default.nix

newhash=$(nix-prefetch-github --json "$owner" "$repo" --rev "$latest_tag" | jq -er .hash)
sed -i "0,/hash = \".*\"/s@hash = \".*\"@hash = \"$newhash\"@" default.nix

echo "$pname updated: $current -> $latest"
