#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

owner=zinja-coder
repo=jadx-ai-mcp
pname=jadx-ai-mcp

current=$(sed -n 's/.*version = "\(.*\)";.*/\1/p' default.nix)
latest_tag=$(gh api "repos/$owner/$repo/releases/latest" --jq '.tag_name')
latest=${latest_tag#V}

if [[ $current == "$latest" ]]; then
    echo "$pname is up-to-date: $latest"
    exit 0
fi

sed -i "s/version = \"$current\"/version = \"$latest\"/" default.nix

newhash=$(nix-prefetch-github --json "$owner" "$repo" --rev "$latest_tag" | jq -r .hash)
sed -i "s@\(hash\) = \".*\"@hash = \"$newhash\"@" default.nix

# Update mvnHash
sed -i 's/mvnHash = ".*"/mvnHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="/' default.nix
newmvnhash=$(nix build --no-link "../..#$pname" 2>&1 | sed -n "s/.*got:\s*\(.*\)/\1/p" || true)
sed -i "s@mvnHash = \".*\"@mvnHash = \"${newmvnhash}\"@" default.nix

echo "$pname updated: $current -> $latest"
