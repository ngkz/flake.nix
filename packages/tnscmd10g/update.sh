#!/usr/bin/env bash
# Update tnscmd10g from the Kali package pool (http://http.kali.org).
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

pname=tnscmd10g
pool="http://http.kali.org/pool/main/t/$pname"

current=$(sed -n 's/^  version = "\([^"]*\)";$/\1/p' default.nix)
# Newest .orig.tar.gz version from the pool listing, e.g. 1.3
latest=$(curl -fsSL "$pool/" | grep -oP "${pname}_\K[0-9][0-9.]*(?=\.orig\.tar\.gz)" | sort -V | tail -n1)

if [[ -z "$latest" ]]; then
    echo "$pname: failed to determine latest version from $pool" >&2
    exit 1
fi

if [[ "$current" == "$latest" ]]; then
    echo "$pname is up-to-date: $latest"
    exit 0
fi

new_hash=$(nix-prefetch-url "http://http.kali.org/pool/main/t/$pname/${pname}_${latest}.orig.tar.gz" --type sha256 |
    xargs -I{} nix hash to-sri --type sha256 "{}")

sed -i "s/^  version = \"[^\"]*\";$/  version = \"$latest\";/" default.nix
sed -i "s|^    hash = \"[^\"]*\";|    hash = \"$new_hash\";|" default.nix

echo "$pname updated: $current -> $latest"
