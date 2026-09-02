#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

pname=llama-cpp-laurent-qwen4exp-rocmfpx
owner=LaurentZuijdwijk
repo=llama.cpp
branch=vulkan/qwen4exp-rocmfpx

current=$(nix eval --no-warn-dirty --raw "../..#${pname}.src.rev")
commit=$(gh api "repos/$owner/$repo/commits/$branch")
latest=$(jq -r .sha <<<"$commit")

if [[ $current == "$latest" ]]; then
    echo "$pname is up-to-date: $latest"
    exit 0
fi

date=$(jq -r .commit.committer.date <<<"$commit" | cut -d'T' -f1)
version=0-unstable-$date

# Stub hash, build to extract correct hash from error
sed -i 's/hash = ".*"/hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="/' default.nix
sed -i "s|rev = \".*\"|rev = \"$latest\"|" default.nix
newhash=$(nix build --no-link "../..#${pname}" 2>&1 || true) && newhash=$(echo "$newhash" | grep -oP 'sha256-[A-Za-z0-9+/=]+' | tail -1)
sed -i "s/version = \".*\"/version = \"$version\"/" default.nix
sed -i "s@hash = \".*\"@hash = \"$newhash\"@" default.nix

echo "$pname updated: $current -> $latest ($version)"
