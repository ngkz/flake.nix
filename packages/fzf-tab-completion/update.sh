#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

pname=fzf-tab-completion
owner=lincheney
repo=fzf-tab-completion
branch=master

current=$(nix eval --no-warn-dirty --raw "../..#${pname}.src.rev")
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
sed -i "s@\(sha256\|hash\) = \".*\"@hash = \"$newhash\"@" default.nix
sed -i "s@cargoHash = \".*\"@cargoHash = lib.fakeHash@" default.nix
newCargoHash=$(nix build --no-link "../..#${pname}" 2>&1 | sed -n "s/.*got:\s*\(.*\)/\1/p" || true)
sed -i "s@cargoHash = .*@cargoHash = \"$newCargoHash\";@" default.nix

echo "$pname updated: $current -> $latest"
