#!/usr/bin/env bash
# Update pyxdia from PyPI. The Python package source is the PyPI sdist
# (fetched via fetchPypi's mirror://pypi URL); setup.py bundles pre-built
# native components from the xdia GitHub release, which we fetch separately
# as xdiaZip / xdialdrTar. All three URLs are version-templated, so only the
# version and the three hashes need updating.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

pname=pyxdia
pypiname=pyxdia
owner=mborgerson
repo=xdia

current=$(sed -n 's/.*version = "\(.*\)";.*/\1/p' default.nix)
json=$(curl -sfL "https://pypi.org/pypi/$pypiname/json")
latest=$(echo "$json" | jq -r '.info.version')

if [[ $current == "$latest" ]]; then
    echo "$pname is up-to-date: $latest"
    exit 0
fi

release_url="https://github.com/$owner/$repo/releases/download/v$latest"

# sdist hash: prefetch the real sdist URL from PyPI; the bytes are identical to
# what fetchPypi's mirror resolves to.
sdist_url=$(echo "$json" | jq -r --arg v "$latest" '.releases[$v][] | select(.packagetype=="sdist") | .url')
src_hash=$(nix hash to-sri --type sha256 "$(nix-prefetch-url --type sha256 "$sdist_url" 2>/dev/null)")

zip_hash=$(nix hash to-sri --type sha256 "$(nix-prefetch-url --type sha256 "$release_url/xdia.zip" 2>/dev/null)")
ldr_hash=$(nix hash to-sri --type sha256 "$(nix-prefetch-url --type sha256 "$release_url/xdialdr.tar.xz" 2>/dev/null)")

sed -i "s/version = \"$current\"/version = \"$latest\"/" default.nix

# Replace the three `hash = "...";` lines in order of appearance: the fetchPypi
# src block first, then the xdiaZip fetchurl block, then the xdialdrTar one.
awk -v s="$src_hash" -v z="$zip_hash" -v l="$ldr_hash" '
  !done_src && /hash = ".*";/ { sub(/hash = ".*";/, "hash = \""s"\";"); done_src=1; print; next }
  !done_zip && /hash = ".*";/ { sub(/hash = ".*";/, "hash = \""z"\";"); done_zip=1; print; next }
  !done_ldr && /hash = ".*";/ { sub(/hash = ".*";/, "hash = \""l"\";"); done_ldr=1; print; next }
  { print }
' default.nix >default.nix.tmp && mv default.nix.tmp default.nix

echo "$pname updated: $current -> $latest"
