#!/usr/bin/env bash
# Update ceccomp from ceccomp/ceccomp
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

pname=ceccomp
owner=ceccomp
repo=ceccomp

current=$(sed -n 's/^  version = "\(.*\)";/\1/p' default.nix)
latest_tag=$(gh api "repos/$owner/$repo/releases/latest" --jq '.tag_name')
latest=${latest_tag#v}

if [[ $current == "$latest" ]]; then
    echo "$pname is up-to-date: $latest"
    exit 0
fi

newhash=$(nix-prefetch-github --json "$owner" "$repo" --rev "$latest_tag" | jq -r .hash)

sed -i "s/^  version = \"$current\";/  version = \"$latest\";/" default.nix
sed -i "s/^    hash = \".*\";/    hash = \"$newhash\";/" default.nix

echo "$pname updated: $current -> $latest"
