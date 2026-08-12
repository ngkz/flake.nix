#!/usr/bin/env bash
# Update angr from PyPI (version source) + GitHub tag (source hash) and the
# cargoDeps vendor hash. angr pins the rest of the suite (archinfo, claripy,
# cle, pyvex) to its own version via the build-system requires, so bump those
# together with this script when they share a release.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

pname=angr
owner=angr
repo=angr

current=$(sed -n 's/.*version = "\(.*\)";.*/\1/p' default.nix)
latest=$(curl -sfL "https://pypi.org/pypi/$pname/json" | jq -r '.info.version')

if [[ $current == "$latest" ]]; then
    echo "$pname is up-to-date: $latest"
    exit 0
fi

sed -i "s/version = \"$current\"/version = \"$latest\"/" default.nix

# src hash: the first `hash = "..."` line (the one in fetchFromGitHub, right
# after `tag = "v${version}";`)
newhash=$(nix-prefetch-github --json "$owner" "$repo" --rev "v$latest" | jq -r .hash)
sed -i "0,/hash = \".*\"/s@hash = \".*\"@hash = \"$newhash\"@" default.nix

# cargoDeps hash: set the hash on the line after `inherit src;` to a
# placeholder, then build to capture the real hash from the mismatch error.
placeholder="sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
sed -i "/inherit src;/{n;s@hash = \".*\";@hash = \"$placeholder\";@}" default.nix
newhash=$(nix build --no-link "../..#$pname" 2>&1 | sed -n "s/.*got:\s*\(.*\)/\1/p" || true)
sed -i "s@hash = \"$placeholder\";@hash = \"$newhash\";@" default.nix

echo "$pname updated: $current -> $latest"
