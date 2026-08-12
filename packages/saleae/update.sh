#!/usr/bin/env bash
# Update saleae from PyPI.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

pname=saleae

current=$(sed -n 's/.*version = "\(.*\)";.*/\1/p' default.nix)
json=$(curl -sfL "https://pypi.org/pypi/$pname/json")
latest=$(jq -r '.info.version' <<<"$json")

if [[ $current == "$latest" ]]; then
    echo "$pname is up-to-date: $latest"
    exit 0
fi

sdist_url=$(jq -r --arg version "$latest" \
    '.releases[$version][] | select(.packagetype == "sdist") | .url' <<<"$json")
newhash=$(nix hash to-sri --type sha256 "$(nix-prefetch-url --type sha256 "$sdist_url" 2>/dev/null)")

sed -i "s/version = \"$current\"/version = \"$latest\"/" default.nix
sed -i "s@hash = \"sha256-.*\"@hash = \"$newhash\"@" default.nix

echo "$pname updated: $current -> $latest"
