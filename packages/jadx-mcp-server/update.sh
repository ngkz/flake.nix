#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

owner=zinja-coder
repo=jadx-mcp-server
branch=main
pname=jadx-mcp-server
# Version follows the jadx-ai-mcp plugin release
version_repo=jadx-ai-mcp

current=$(sed -n 's/.*version = "\(.*\)";.*/\1/p' default.nix)
# Upstream tags releases as v<X.Y.Z> in the plugin repository
latest_tag=$(git ls-remote --tags --sort=-v:refname "https://github.com/$owner/$version_repo" |
    sed -n 's@.*refs/tags/\(v[0-9][0-9.]*\)$@\1@p' | head -1)
latest=${latest_tag#v}

if [[ -z "$latest" ]]; then
    echo "Could not find latest tag for $version_repo" >&2
    exit 1
fi

if [[ $current == "$latest" ]]; then
    echo "$pname is up-to-date: $latest"
    exit 0
fi

# The server repository has no tags: its release commit is the one bumping the
# printed version string, so search the commit messages.
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
git clone -q --single-branch --branch "$branch" --depth 200 "https://github.com/$owner/$repo" "$tmp/$repo"

rev=$(git -C "$tmp/$repo" log -n1 --format=%H --grep="$latest_tag" HEAD)
if [[ -z "$rev" ]]; then
    echo "Could not find release commit for $latest_tag" >&2
    exit 1
fi

sed -i "s/version = \"$current\"/version = \"$latest\"/" default.nix
sed -i "s/rev = \".*\";/rev = \"$rev\";/" default.nix

newhash=$(nix-prefetch-github --json "$owner" "$repo" --rev "$rev" | jq -r .hash)
sed -i "s@\(hash\) = \".*\"@hash = \"$newhash\"@" default.nix

echo "$pname updated: $current -> $latest (rev: $rev)"
