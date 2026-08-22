#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

pname=pi-tps-meter
owner=vskrch
repo=pi-tps-meter

current_version=$(sed -n 's/.*version = "\(.*\)";.*/\1/p' default.nix)
current_rev=$(sed -n 's/.*rev = "\([0-9a-f]*\)";.*/\1/p' default.nix)

latest_rev=$(curl -fsSL --max-time 30 "https://api.github.com/repos/$owner/$repo/commits?per_page=1" | jq -r '.[0].sha')
latest_version=$(curl -fsSL --max-time 30 "https://raw.githubusercontent.com/$owner/$repo/HEAD/package.json" | jq -r '.version')

if [[ "$current_rev" == "$latest_rev" && "$current_version" == "$latest_version" ]]; then
    echo "$pname is up-to-date: $latest_version ($latest_rev)"
    exit 0
fi

# Update version, rev and stub the src hash
sed -i "s/version = \"$current_version\"/version = \"$latest_version\"/" default.nix
sed -i "s/rev = \"$current_rev\"/rev = \"$latest_rev\"/" default.nix
sed -i 's/^\(    hash = \)".*"/\1"sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="/' default.nix

out=$(nix build --no-link "../..#${pname}" 2>&1 || true)
# Assumes a fixed-output failure reports: specified: <hash>  /  got: <hash>
spec=
got=
while IFS= read -r line; do
    [[ -z "$spec" && "$line" =~ ^[[:space:]]*specified:[[:space:]]*(.+)$ ]] && spec="${BASH_REMATCH[1]}"
    [[ -z "$got" && "$line" =~ ^[[:space:]]*got:[[:space:]]*(.+)$ ]] && got="${BASH_REMATCH[1]}"
done <<<"$out"

if [[ -n "$spec" && -n "$got" ]]; then
    sed -i "s|${spec}|${got}|" default.nix
    echo "updated hash: $spec -> $got"
fi

echo "$pname updated: $current_version -> $latest_version"