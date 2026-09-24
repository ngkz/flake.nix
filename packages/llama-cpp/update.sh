#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

pname=llama-cpp
owner=ggml-org
repo=llama.cpp

current=$(sed -n 's/.*version = "\(.*\)";.*/\1/p' default.nix)
# The bNNNNN nightly releases are pre-releases, so the latest release is the
# newest semantic version. Only release tags use the vX.Y.Z shape.
latest=$(gh api "repos/$owner/$repo/releases" --jq '[.[] | select(.tag_name | startswith("v")) | .tag_name | ltrimstr("v") | select(test("^[0-9]+(\\.[0-9]+)+$"))][0]')

if [[ $current == "$latest" ]]; then
    echo "$pname is up-to-date: $latest"
    exit 0
fi

# llama.cpp reads the build number and commit from git, which the release
# tarball does not ship. Every release carries the matching nightly tag as an
# asset.
build_number=$(curl -fsSL "https://github.com/$owner/$repo/releases/download/v$latest/nightly-tag.txt" | sed 's/^b//')
build_commit=$(gh api "repos/$owner/$repo/commits/v$latest" --jq '.sha[0:7]')

sed -i "s/version = \"$current\"/version = \"$latest\"/" default.nix
sed -i "s/buildNumber = \".*\"/buildNumber = \"$build_number\"/" default.nix
sed -i "s/buildCommit = \".*\"/buildCommit = \"$build_commit\"/" default.nix
sed -i "s/hash = \".*\"/hash = \"sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=\"/" default.nix
sed -i "s/npmDepsHash = \".*\"/npmDepsHash = \"sha256-BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBA=\"/" default.nix

for ((i = 0; i < 2; i++)); do
    out=$(nix build --no-link "../..#${pname}" 2>&1 || true)
    specified=$(sed -n "s/.*specified:\s*\(.*\)/\1/p" <<<"$out")
    got=$(sed -n "s/.*got:\s*\(.*\)/\1/p" <<<"$out")
    if [[ -z $specified || -z $got ]]; then
        echo "failed to extract hashes for $pname, nix build output:" >&2
        echo "$out" >&2
        exit 1
    fi
    echo "updating hash: $specified -> $got"
    sed -i "s|ash = \"$specified\"|ash = \"$got\"|" default.nix
done

echo "$pname updated: $current -> $latest"