#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

owner=zinja-coder
repo=jadx-ai-mcp
pname=jadx-ai-mcp

current=$(sed -n 's/.*version = "\(.*\)";.*/\1/p' default.nix)
# Upstream tags releases as v<X.Y.Z>
latest_tag=$(git ls-remote --tags --sort=-v:refname "https://github.com/$owner/$repo" |
    sed -n 's@.*refs/tags/\(v[0-9][0-9.]*\)$@\1@p' | head -1)
latest=${latest_tag#v}

if [[ -z "$latest" ]]; then
    echo "Could not find latest tag for $repo" >&2
    exit 1
fi

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
