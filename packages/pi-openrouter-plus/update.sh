#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

pname=pi-openrouter-plus
owner=olixis
repo=pi-openrouter-plus

current_version=$(sed -n 's/.*version = "\(.*\)";.*/\1/p' default.nix)
current_rev=$(sed -n 's/.*rev = "\([0-9a-f]*\)";.*/\1/p' default.nix)

latest_rev=$(curl -fsSL --max-time 30 "https://api.github.com/repos/$owner/$repo/commits?per_page=1" | jq -r '.[0].sha')
latest_version=$(curl -fsSL --max-time 30 "https://raw.githubusercontent.com/$owner/$repo/HEAD/package.json" | jq -r '.version')

if [[ "$current_rev" == "$latest_rev" && "$current_version" == "$latest_version" ]]; then
    echo "$pname is up-to-date: $latest_version ($latest_rev)"
    exit 0
fi

# Update version, rev and stub both hashes
sed -i "s/version = \"$current_version\"/version = \"$latest_version\"/" default.nix
sed -i "s/rev = \"$current_rev\"/rev = \"$latest_rev\"/" default.nix
sed -i 's/^\(    hash = \)".*"/\1"sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="/' default.nix
sed -i 's/^\(  npmDepsHash = \)".*"/\1"sha256-BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBA="/' default.nix

for ((i = 0; i < 2; i++)); do
    out=$(nix build --no-link "../..#${pname}" 2>&1 || true)
    # Extract all specified/got pairs from the build log
    specs=()
    got=()
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*specified:[[:space:]]*(.+)$ ]]; then
            specs+=("${BASH_REMATCH[1]}")
        elif [[ "$line" =~ ^[[:space:]]*got:[[:space:]]*(.+)$ ]]; then
            got+=("${BASH_REMATCH[1]}")
        fi
    done <<<"$out"

    # Update hashes line by line (preserves semicolons and structure)
    for ((j = 0; j < ${#specs[@]} && j < ${#got[@]}; j++)); do
        echo "updating hash: ${specs[$j]} -> ${got[$j]}"
        if [[ $j -eq 0 ]]; then
            sed -i "s|${specs[$j]}|${got[$j]}|" default.nix
        else
            sed -i "/npmDepsHash/s|${specs[$j]}|${got[$j]}|" default.nix
        fi
    done
done

echo "$pname updated: $current_version -> $latest_version"
