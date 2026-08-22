#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

uuid="battery-usage-wattmeter@halfmexicanhalfamazing.gmail.com"
pname=battery-usage-wattmeter

# Get latest version from extensions.gnome.org API (paginated)
latest_version=$(curl -sL "https://extensions.gnome.org/api/v1/extensions/${uuid}/versions/" | python3 -c "
import json, sys, urllib.request
data = json.load(sys.stdin)
versions = [r['version'] for r in data.get('results', [])]
next_url = data.get('next')
while next_url:
    resp = urllib.request.urlopen(next_url)
    data = json.loads(resp.read())
    versions.extend(r['version'] for r in data.get('results', []))
    next_url = data.get('next')
print(max(versions) if versions else 0)
")

if [[ "$latest_version" -eq 0 ]]; then
    echo "No version found on extensions.gnome.org" >&2
    exit 1
fi

# Download extension from extensions.gnome.org and compute hash
uuid_nosym="${uuid//@/}"
zip_url="https://extensions.gnome.org/extension-data/${uuid_nosym}.v${latest_version}.shell-extension.zip"

hash_output=$(nix-prefetch-url --unpack "$zip_url" 2>&1)
sha256=$(echo "$hash_output" | tail -1)

# Fetch metadata.json from downloaded extension
store_path=$(echo "$hash_output" | head -1 | sed "s|path is '\(.*\)'|\1|")
metadata_b64=$(cat "${store_path}/metadata.json" | base64 -w0)

# Update default.nix in place
sed -i "s|version = \".*\"|version = \"${latest_version}\"|" default.nix
sed -i "s|sha256 = \".*\"|sha256 = \"${sha256}\"|" default.nix
sed -i "s|metadata = \".*\"|metadata = \"${metadata_b64}\"|" default.nix

echo "$pname updated to v$latest_version"
