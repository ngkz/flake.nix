#!/usr/bin/env bash
# Update xdis from GitHub tag (source hash)
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

pname=xdis
owner=rocky
repo=python-xdis

current=$(sed -n 's/.*version = "\(.*\)";.*/\1/p' default.nix)
latest=$(curl -sfL "https://api.github.com/repos/$owner/$repo/releases/latest" | jq -r '.tag_name')

if [[ "$current" == "$latest" ]] || [[ "$latest" == "6.3.0" ]]; then
    echo "$pname is up-to-date: $latest"
    exit 0
fi

version="$latest"
newhash=$(nix-prefetch-github --json "$owner" "$repo" --rev "$latest" | jq -r .hash)
sed -i "s/version = \".*\"/version = \"$version\"/" default.nix
sed -i "s|rev = \".*\"|rev = \"$latest\"|" default.nix
sed -i "s@\(sha256\|hash\) = \".*\"@hash = \"$newhash\"@" default.nix

echo "$pname updated: $current -> $latest"
