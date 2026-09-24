#!/usr/bin/env bash
# Update strixec from raimondomartire/ms-s1-max-fans-control
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

owner=raimondomartire
repo=ms-s1-max-fans-control

current_rev=$(sed -n 's/.*rev = "\(.*\)";.*/\1/p' src.nix)
commit=$(gh api "repos/$owner/$repo/commits/main")
latest=$(jq -r .sha <<<"$commit")

if [[ $current_rev == "$latest" ]]; then
    echo "strixec is up-to-date: $latest"
    exit 0
fi

# Upstream ships no releases; the program version lives in the GUI script.
upstream_version=$(gh api "repos/$owner/$repo/contents/bin/strixec-gui" --jq '.content' | base64 -d | sed -n 's/^VERSION = "\(.*\)"/\1/p')
date=$(jq -r .commit.committer.date <<<"$commit" | cut -d'T' -f1)
newhash=$(nix-prefetch-github --json "$owner" "$repo" --rev "$latest" | jq -r .hash)

sed -i "s|upstreamVersion = \"[^\"]*\"|upstreamVersion = \"$upstream_version\"|" src.nix
sed -i "s|version = \"\${upstreamVersion}-unstable-[^\"]*\"|version = \"\${upstreamVersion}-unstable-$date\"|" src.nix
sed -i "s|rev = \"$current_rev\"|rev = \"$latest\"|" src.nix
sed -i "s|hash = \"[^\"]*\"|hash = \"$newhash\"|" src.nix

echo "strixec updated: $current_rev -> $latest ($upstream_version-unstable-$date)"
