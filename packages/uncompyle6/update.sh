#!/usr/bin/env bash
# Update uncompyle6 from PyPI (version source) + GitHub tag (source hash)
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

pname=uncompyle6
owner=rocky
repo=python-uncompyle6

current=$(sed -n 's/.*version = "\(.*\)";.*/\1/p' default.nix)
latest=$(curl -sfL "https://pypi.org/pypi/$pname/json" | jq -r '.info.version')

if [[ $current == "$latest" ]]; then
    echo "$pname is up-to-date: $latest"
    exit 0
fi

sed -i "s/version = \"$current\"/version = \"$latest\"/" default.nix
newhash=$(nix-prefetch-github --json "$owner" "$repo" --rev "$latest" | jq -r .hash)
sed -i "s@\(sha256\|hash\) = \".*\"@hash = \"$newhash\"@" default.nix

echo "$pname updated: $current -> $latest"
