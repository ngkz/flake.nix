#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

pname=edbgserver
owner=Satar07
repo=edbgserver

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

placeholder="sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
sed -i "s@cargoHash = \".*\";@cargoHash = \"$placeholder\";@" default.nix

newCargoHash=$(nix build --no-link "../..#$pname" 2>&1 | sed -n 's/.*got:[[:space:]]*\(sha256-[^[:space:]]*\).*/\1/p' | tail -1 || true)
if [[ -z $newCargoHash ]]; then
    echo "failed to determine cargo hash" >&2
    exit 1
fi
sed -i "s@cargoHash = \"$placeholder\";@cargoHash = \"$newCargoHash\";@" default.nix

echo "$pname updated: $current -> $latest"
