#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

pname=ghidra-cli
owner=akiselev
repo=ghidra-cli
placeholder=sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=

current=$(sed -n 's/^  version = "\([^\"]*\)";/\1/p' default.nix)
latest_tag=$(gh api "repos/$owner/$repo/releases/latest" --jq '.tag_name')
latest=${latest_tag#v}

if [[ $current == "$latest" ]]; then
    echo "$pname is up-to-date: $latest"
    exit 0
fi

source_hash=$(nix-prefetch-github --json "$owner" "$repo" --rev "$latest_tag" | jq -er .hash)
sed -i "s|^  version = \".*\";|  version = \"$latest\";|" default.nix
sed -i "0,/^    hash = \".*\";/s|^    hash = \".*\";|    hash = \"$source_hash\";|" default.nix
sed -i "s|^  cargoHash = \".*\";|  cargoHash = \"$placeholder\";|" default.nix

build_output=$(nix build --no-link "../..#$pname" 2>&1 || true)
cargo_hash=$(sed -n 's/^[[:space:]]*got:[[:space:]]*\(sha256-[^[:space:]]*\).*$/\1/p' <<<"$build_output")

if [[ -z $cargo_hash ]]; then
    echo "cargo hash not found in nix build output" >&2
    exit 1
fi

sed -i "s|^  cargoHash = \".*\";|  cargoHash = \"$cargo_hash\";|" default.nix
echo "$pname updated: $current -> $latest"
