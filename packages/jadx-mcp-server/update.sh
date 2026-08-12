#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

owner=zinja-coder
repo=jadx-mcp-server
branch=main
pattern="release: v"
pname=jadx-mcp-server

find_latest_match() {
    local pattern=$1
    local page=1
    local per_page=100

    while :; do
        resp=$(gh api "repos/$owner/$repo/commits?sha=$branch&per_page=$per_page&page=$page")

        # API error handling (Not Found, rate limit, etc.)
        if echo "$resp" | jq -e 'type=="object" and has("message")' >/dev/null 2>&1; then
            echo "GitHub API error: $(echo "$resp" | jq -r '.message')" >&2
            return 1
        fi

        # Find the first commit in this page whose commit.message contains the substring
        commit=$(echo "$resp" |
            jq -r --arg pat "$pattern" 'map(select(.commit.message | index($pat))) | .[0].sha // empty')

        if [ -n "$commit" ]; then
            echo "$commit"
            return
        fi

        # If fewer than per_page commits returned, no more pages
        len=$(echo "$resp" | jq 'length')
        if [ "$len" -lt "$per_page" ]; then
            echo "No matching commit found" >&2
            return 1
        fi

        page=$((page + 1))
    done
}

current=$(sed -n 's/.*version = "\(.*\)";.*/\1/p' default.nix)
latest_tag=$(gh api "repos/$owner/jadx-ai-mcp/releases/latest" --jq '.tag_name')
latest=${latest_tag#V}

if [[ $current == "$latest" ]]; then
    echo "$pname is up-to-date: $latest"
    exit 0
fi

sed -i "s/version = \"$current\"/version = \"$latest\"/" default.nix

rev=$(find_latest_match "$pattern")

if [[ -z "$rev" ]]; then
    echo "Could not find release commit for v$latest" >&2
    exit 1
fi

sed -i "s/rev = \".*\";/rev = \"$rev\";/" default.nix

newhash=$(nix-prefetch-github --json "$owner" "$repo" --rev "$rev" | jq -r .hash)
sed -i "s@\(hash\) = \".*\"@hash = \"$newhash\"@" default.nix

echo "$pname updated: $current -> $latest (rev: $rev)"
