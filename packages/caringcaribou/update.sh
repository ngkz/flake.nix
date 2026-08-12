#!/usr/bin/env bash
# Update caringcaribou from the latest commit on the upstream master branch.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

pname=caringcaribou
owner=CaringCaribou
repo=caringcaribou
branch=master

current_rev=$(sed -n 's/.*rev = "\([0-9a-f]\{40\}\)";.*/\1/p' default.nix)
commit=$(gh api "repos/$owner/$repo/commits/$branch")
latest_rev=$(jq -er '.sha' <<<"$commit")

if [[ "$current_rev" == "$latest_rev" ]]; then
    echo "$pname is up-to-date: $latest_rev"
    exit 0
fi

pyproject_version=$(curl -fsSL "https://raw.githubusercontent.com/$owner/$repo/$latest_rev/pyproject.toml" |
    sed -n 's/^version = "\([^"]*\)"$/\1/p' | head -n1)
commit_date=$(gh api "repos/$owner/$repo/commits/$latest_rev" --jq '.commit.author.date' | cut -d'T' -f1)
version="${pyproject_version}-unstable-${commit_date}"

if [[ -z "$version" ]]; then
    echo "$pname: failed to determine the version from pyproject.toml" >&2
    exit 1
fi

new_hash=$(nix-prefetch-github --json "$owner" "$repo" --rev "$latest_rev" | jq -er '.hash')

sed -i "s/version = \"[^\"]*\";/version = \"$version\";/" default.nix
sed -i "s/rev = \"[0-9a-f]\{40\}\";/rev = \"$latest_rev\";/" default.nix
sed -i "/owner = \"$owner\";/,/};/ s|hash = \"[^\"]*\";|hash = \"$new_hash\";|" default.nix

echo "$pname updated: $current_rev -> $latest_rev ($version)"
