#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

pname=llama-cpp
owner=ggml-org
repo=llama.cpp

current=$(sed -n 's/.*version = "\(.*\)";.*/\1/p' default.nix)
latest=$(gh api "repos/$owner/$repo/releases" --jq '[.[] | select(.tag_name | startswith("v") | not)][0].tag_name' | sed 's/^b//')

if [[ $current == "$latest" ]]; then
    echo "$pname is up-to-date: $latest"
    exit 0
fi

sed -i "s/version = \"$current\"/version = \"$latest\"/" default.nix
sed -i "s/hash = \".*\"/hash = \"sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=\"/" default.nix
sed -i "s/npmDepsHash = \".*\"/npmDepsHash = \"sha256-BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBA=\"/" default.nix

for ((i = 0; i < 2; i++)); do
    out=$(nix build --no-link "../..#${pname}" 2>&1 || true)
    specified=$(sed -n "s/.*specified:\s*\(.*\)/\1/p" <<<"$out")
    got=$(sed -n "s/.*got:\s*\(.*\)/\1/p" <<<"$out")
    echo "updating hash: $specified -> $got"
    sed -i "s|ash = \"$specified\"|ash = \"$got\"|" default.nix
done

echo "$pname updated: $current -> $latest"
