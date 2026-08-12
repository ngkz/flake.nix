#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

pname=r8152
owner=wget
repo=realtek-r8152-linux

current=$(nix eval --no-warn-dirty --raw "../..#${pname}.version")
latest_tag=$(gh api "repos/$owner/$repo/releases/latest" --jq '.tag_name')
latest=$(echo "$latest_tag" | cut -c2-)

if [[ $current == $latest ]]; then
    echo "$pname is up-to-date: $latest"
    exit 0
fi

sed -i "s/version = \"$current\"/version = \"$latest\"/" default.nix
newhash=$(nix-prefetch-github --json "$owner" "$repo" --rev "$latest_tag" | jq -r .hash)
sed -i "s@\(sha256\|hash\) = \".*\"@hash = \"$newhash\"@" default.nix

echo "$pname updated: $current -> $latest"
