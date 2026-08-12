#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

pname=legacycrypt
pypipname=$pname

current=$(sed -n 's/.*version = "\(.*\)";.*/\1/p' default.nix)
latest=$(curl -sfL "https://pypi.org/pypi/${pypipname}/json" | jq -r ".info.version")

if [[ $current == "$latest" ]]; then
    echo "$pname is up-to-date: $latest"
    exit 0
fi

sed -i "s/version = \"$current\"/version = \"$latest\"/" default.nix
newhash=$(nix build --no-link "../..#${pname}" 2>&1 | sed -n "s/.*got:\s*\(.*\)/\1/p" || true)
sed -i "s@\(sha256\|hash\) = \".*\"@hash = \"$newhash\"@" default.nix

echo "$pname updated: $current -> $latest"
