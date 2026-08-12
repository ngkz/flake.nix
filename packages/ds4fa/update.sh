#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

pname=ds4fa
owner=julianmb
repo=ds4fa
branch=main

current=$(sed -n 's/.*rev = "\(.*\)";.*/\1/p' default.nix)
commit=$(gh api "repos/$owner/$repo/commits/$branch")
latest=$(jq -r .sha <<<"$commit")

if [[ $current == "$latest" ]]; then
    echo "$pname is up-to-date: $latest"
    exit 0
fi

date=$(jq -r .commit.committer.date <<<"$commit" | cut -d'T' -f1)
version=0-unstable-$date
newhash=$(nix-prefetch-github --json "$owner" "$repo" --rev "$latest" | jq -r .hash)
sed -i "s/version = \".*\"/version = \"$version\"/" default.nix
sed -i "s|rev = \".*\"|rev = \"$latest\"|" default.nix
sed -i "s@hash = \".*\"@hash = \"$newhash\"@" default.nix

echo "$pname updated: $current -> $latest"
