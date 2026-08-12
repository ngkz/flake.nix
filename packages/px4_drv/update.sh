#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

pname=px4_drv
owner=tsukumijima
repo=px4_drv

current=$(sed -n 's/.*version = "\(.*\)";.*/\1/p' src.nix)
latest_tag=$(gh api "repos/$owner/$repo/releases/latest" --jq '.tag_name')
latest=$(echo "$latest_tag" | cut -c2-)

if [[ $current == $latest ]]; then
    echo "$pname is up-to-date: $latest"
    exit 0
fi

sed -i "s/version = \"$current\"/version = \"$latest\"/" src.nix
newhash=$(nix-prefetch-github --json "$owner" "$repo" --rev "$latest_tag" | jq -r .hash)
sed -i "s@\(sha256\|hash\) = \".*\"@hash = \"$newhash\"@" src.nix

echo "$pname updated: $current -> $latest"
