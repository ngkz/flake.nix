#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

pname=skk-dicts-jawiki
owner=tokuhirom
repo=jawiki-kana-kanji-dict

current=$(sed -n 's/.*version = "\(.*\)";.*/\1/p' default.nix)
release=$(gh api "repos/$owner/$repo/releases/latest")
tag=$(jq -r '.tag_name' <<<"$release")
latest="${tag#v}"
download_url=$(jq -r '.assets[] | select(.name=="SKK-JISYO.jawiki") | .browser_download_url' <<<"$release")
digest=$(jq -r '.assets[] | select(.name=="SKK-JISYO.jawiki") | .digest' <<<"$release")
hash="${digest#sha256:}"
hash_full=$(nix hash to-sri --type sha256 "$hash")

if [[ "$current" == "$latest" ]]; then
    echo "$pname is up-to-date"
    exit 0
fi

sed -i "s/version = \".*\"/version = \"$latest\"/" default.nix
sed -i "s@\(sha256\|hash\) = \".*\"@hash = \"$hash_full\"@" default.nix
echo "$pname updated: $current -> $latest"
