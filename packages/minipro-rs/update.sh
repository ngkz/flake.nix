#!/usr/bin/env bash
# Update minipro-rs: version, GitLab archive hash and the cargo/npm hashes of
# both packages (CLI, GUI frontend, GUI Tauri backend).
set -euo pipefail

owner=arcturus8081
repo=minipro-rs
project="${owner}%2F${repo}"
fakeHash="sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="

cd "$(git rev-parse --show-toplevel)"

# Latest upstream tag (tags are vMAJOR.MINOR.PATCH)
latest_tag=$(
    curl -sf "https://gitlab.com/api/v4/projects/${project}/repository/tags?per_page=100" |
        jq -r '.[].name' |
        grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' |
        sed -n 1p
) || true
if [[ -z ${latest_tag} ]]; then
    echo "error: no upstream tag found" >&2
    exit 1
fi
latest_version="${latest_tag#v}"
echo "Latest version: ${latest_version}"

update_attr() {
    local file="$1" attr="$2" value="$3"

    sed -i -E "s,${attr} = \"sha256-[^\"]*\";,${attr} = \"${value}\";," "$file"
}

# Stub version and hashes so a build failure reports the real ones
update_attr packages/minipro-rs/src.nix hash "$fakeHash"
update_attr packages/minipro-rs/cli.nix cargoHash "$fakeHash"
update_attr packages/minipro-rs/gui.nix cargoHash "$fakeHash"
update_attr packages/minipro-rs/gui.nix npmDepsHash "$fakeHash"
# Track the newest tag again (src.nix may pin an unreleased commit)
sed -i -E \
    -e "s,version = \"[^\"]*\";,version = \"${latest_version}\";" \
    -e "s,rev = \"[^\"]*\";,rev = \"${latest_tag}\";," packages/minipro-rs/src.nix

# Source hash of the GitLab archive tarball (fetchFromGitLab unpacks it)
src_hash=$(
    nix hash to-sri --type sha256 \
        "$(nix-prefetch-url --unpack "https://gitlab.com/api/v4/projects/${project}/repository/archive.tar.gz?sha=${latest_tag}")"
)
update_attr packages/minipro-rs/src.nix hash "$src_hash"

# The remaining hashes are fixed-output derivations: build, read the hash back
# from the mismatch message and assign it to the attribute of the failed
# derivation (npm-deps -> npmDepsHash, vendor-staging -> cargoHash).
log=$(mktemp)
trap 'rm -f "$log"' EXIT
for attr in minipro-rs-cli minipro-rs-gui; do
    for _ in {1..3}; do
        if nix build --no-link ".#${attr}" >"$log" 2>&1; then
            echo "${attr}: build OK"
            break
        fi
        if ! grep -q 'hash mismatch in fixed-output derivation' "$log"; then
            cat "$log"
            exit 1
        fi
        got=$(grep -oE 'got: sha256-[A-Za-z0-9+/=]*' "$log" | sed -n 1p | cut -d' ' -f2)
        if grep -q 'npm-deps' "$log"; then
            file=packages/minipro-rs/gui.nix
            hashattr=npmDepsHash
        elif grep -q 'minipro-rs-gui-.*-vendor' "$log"; then
            file=packages/minipro-rs/gui.nix
            hashattr=cargoHash
        else
            file=packages/minipro-rs/cli.nix
            hashattr=cargoHash
        fi
        echo "${attr}: updating ${hashattr} in ${file}"
        update_attr "$file" "$hashattr" "$got"
    done
done
