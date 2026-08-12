#!/usr/bin/env bash
# Update pydemumble from the upstream GitHub repo (angr/pydemumble). Version
# source is PyPI; the source hash comes from nix-prefetch-github at the
# v<version> tag with --fetch-submodules (nanobind + its nested robin_map are
# git submodules that get compiled from source).
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

pname=pydemumble
pypiname=pydemumble
owner=angr
repo=pydemumble

current=$(sed -n 's/.*version = "\(.*\)";.*/\1/p' default.nix)
latest=$(curl -sfL "https://pypi.org/pypi/$pypiname/json" | jq -r '.info.version')

if [[ $current == "$latest" ]]; then
    echo "$pname is up-to-date: $latest"
    exit 0
fi

sed -i "s/version = \"$current\"/version = \"$latest\"/" default.nix
newhash=$(nix-prefetch-github --json "$owner" "$repo" --rev "v$latest" --fetch-submodules | jq -r .hash)
sed -i "s@\(sha256\|hash\) = \".*\"@hash = \"$newhash\"@" default.nix

echo "$pname updated: $current -> $latest"
