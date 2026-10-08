#!/usr/bin/env bash
# Update angr-data from PyPI (version source) + GitHub tag (source hash)
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

pname=angr-data
owner=angr
repo=angr-data

current=$(sed -n 's/.*version = "\(.*\)";.*/\1/p' default.nix)
latest=$(curl -sfL "https://pypi.org/pypi/$pname/json" | jq -r '.info.version')

if [[ $current == "$latest" ]]; then
    echo "$pname is up-to-date: $latest"
    exit 0
fi

# packages/angr pins angr-data~=0.1.1 (i.e. <0.2). Newer releases break the
# angr build, so stay on the 0.1.x line.
upper=0.2
if [[ $(printf '%s\n%s\n' "$latest" "$upper" | sort -V | head -n1) == "$upper" ]]; then
    echo "$pname $latest is beyond angr's pin (<$upper): keeping $current"
    exit 0
fi

sed -i "s/version = \"$current\"/version = \"$latest\"/" default.nix
newhash=$(nix-prefetch-github --json "$owner" "$repo" --rev "v$latest" | jq -r .hash)
sed -i "s@\(sha256\|hash\) = \".*\"@hash = \"$newhash\"@" default.nix

echo "$pname updated: $current -> $latest"
