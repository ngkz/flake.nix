#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

pname=battery-usage-wattmeter
owner=halfmexican
repo=battery-usage-wattmeter-extension
branch=main

# Get latest commit from main branch
current_rev=$(nix eval --no-warn-dirty --raw "../..#${pname}.src.rev" 2>/dev/null || echo "0")
latest=$(gh api "repos/$owner/$repo/branches/$branch" --jq '.commit.sha')

if [[ "$current_rev" == "$latest" ]]; then
    echo "$pname is up-to-date: $latest"
    exit 0
fi

# Get version from GitHub metadata.json on main branch
metadata=$(curl -sL "https://raw.githubusercontent.com/$owner/$repo/refs/heads/$branch/metadata.json")
version=$(jq -r '.version' <<<"$metadata")

# Get hash from GitHub
newhash=$(nix-prefetch-github --json "$owner" "$repo" --rev "$latest" | jq -r .hash)

# Update default.nix
sed -i "s/rev = \".*\"/rev = \"$latest\"/" default.nix
sed -i "s/version = \".*\"/version = \"$version\"/" default.nix
sed -i "s/hash = \".*\"/hash = \"$newhash\"/" default.nix

echo "$pname updated: $current_rev -> $latest (v$version)"
