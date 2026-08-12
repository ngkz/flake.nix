#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

pname=ptrlib
owner=ptr-yudai
repo=ptrlib

current=$(sed -n 's/.*rev = "\(.*\)";.*/\1/p' default.nix)
commit=$(gh api "repos/$owner/$repo/commits/master")
latest=$(jq -r .sha <<<"$commit")

if [[ $current == "$latest" ]]; then
    echo "$pname is up-to-date: $latest"
    exit 0
fi

version=$(curl -sfL "https://raw.githubusercontent.com/$owner/$repo/$latest/setup.py" | sed -n "s/.*version='\\(.*\\)'.*/\1/p")
newhash=$(nix-prefetch-github --json "$owner" "$repo" --rev "$latest" | jq -r .hash)
sed -i "s/version = \".*\"/version = \"$version\"/" default.nix
sed -i "s|rev = \".*\"|rev = \"$latest\"|" default.nix
sed -i "s@\(sha256\|hash\) = \".*\"@hash = \"$newhash\"@" default.nix

echo "$pname updated: $current -> $latest ($version)"
