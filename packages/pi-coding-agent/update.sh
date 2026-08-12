#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

pname=pi-coding-agent
owner=earendil-works
repo=pi

current=$(sed -n 's/.*version = "\(.*\)";.*/\1/p' default.nix)
latest=$(gh api "repos/$owner/$repo/releases/latest" --jq '.tag_name' | cut -c2-)

if [[ $current == "$latest" ]]; then
    echo "$pname is up-to-date: $latest"
    exit 0
fi

# Update default.nix version and hashes
sed -i "s/version = \"$current\"/version = \"$latest\"/" default.nix
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
            # Update source hash line
            sed -i "s|${specs[$j]}|${got[$j]}|" default.nix
        else
            # Update npmDepsHash line (more specific pattern)
            sed -i "/npmDepsHash/s|${specs[$j]}|${got[$j]}|" default.nix
        fi
    done
done

echo "$pname updated: $current -> $latest"
