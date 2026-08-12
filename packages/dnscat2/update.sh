#!/usr/bin/env bash
# Update dnscat2 from the latest commit on the upstream master branch.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

pname=dnscat2
owner=iagox86
repo=dnscat2
branch=master

current_rev=$(sed -n 's/.*rev = "\([0-9a-f]\{40\}\)";.*/\1/p' default.nix)
commit=$(gh api "repos/$owner/$repo/commits/$branch")
latest_rev=$(jq -er '.sha' <<<"$commit")

if [[ "$current_rev" == "$latest_rev" ]]; then
    echo "$pname is up-to-date: $latest_rev"
    exit 0
fi

# dnscat2 has no tags; the server takes the client's version, e.g. "v0.07".
client_version=$(curl -fsSL "https://raw.githubusercontent.com/$owner/$repo/$latest_rev/client/dnscat.c" |
    sed -n 's/.*define VERSION "\([^"]*\)".*/\1/p')
commit_date=$(gh api "repos/$owner/$repo/commits/$latest_rev" --jq '.commit.author.date' | cut -dT -f1)
version="${client_version#v}-unstable-${commit_date}"

if [[ -z "$client_version" ]]; then
    echo "$pname: failed to determine the version from client/dnscat.c" >&2
    exit 1
fi

new_hash=$(nix-prefetch-github --json "$owner" "$repo" --rev "$latest_rev" | jq -er '.hash')

sed -i "s/^  version = \"[^\"]*\";/  version = \"$version\";/" default.nix
sed -i "s/rev = \"[^\"]*\";/rev = \"$latest_rev\";/" default.nix
sed -i "s@hash = \"[^\"]*\";@hash = \"$new_hash\";@" default.nix

echo "$pname updated: $current_rev -> $latest_rev ($version)"
