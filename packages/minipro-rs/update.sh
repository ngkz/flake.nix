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

update_attr() {
    local file="$1" attr="$2" value="$3"

    sed -i -E "s,${attr} = \"sha256-[^\"]*\";,${attr} = \"${value}\";," "$file"
}

# src.nix may pin an unreleased commit on top of a release
# (version = "X.Y.Z-unstable-..."): follow the newest tag only once upstream
# releases something newer than X.Y.Z.
version=$(sed -nE 's/^  version = "([^"]*)";/\1/p' packages/minipro-rs/src.nix)
pinned=${version%%-unstable*}
newest=$(printf '%s\n%s\n' "${latest_version}" "${pinned}" | sort -V | tail -1)
new_release=
if [[ ${newest} == "${latest_version}" && ${pinned} != "${latest_version}" ]]; then
    new_release=1
fi
# A hash stubbed by an aborted run has to be refreshed too, but without moving
# the revision.
if [[ -z ${new_release} ]] && ! grep -q "${fakeHash}" packages/minipro-rs/*.nix; then
    echo "minipro-rs is up-to-date: ${version}"
    exit 0
fi

# Stub the hashes so a build failure reports the real ones
update_attr packages/minipro-rs/src.nix hash "$fakeHash"
update_attr packages/minipro-rs/cli.nix cargoHash "$fakeHash"
update_attr packages/minipro-rs/gui.nix cargoHash "$fakeHash"
update_attr packages/minipro-rs/gui.nix npmDepsHash "$fakeHash"

if [[ -n ${new_release} ]]; then
    sed -i -E \
        -e "s,version = \"[^\"]*\";,version = \"${latest_version}\";," \
        -e "s,rev = \"[^\"]*\";,rev = \"${latest_tag}\";," packages/minipro-rs/src.nix
fi

# Source hash of the GitLab archive tarball (fetchFromGitLab unpacks it). The
# revision is the tag or the pinned commit, so read it back.
rev=$(sed -nE 's/^  rev = "([^"]*)";/\1/p' packages/minipro-rs/src.nix)
src_hash=$(
    nix hash to-sri --type sha256 \
        "$(nix-prefetch-url --unpack "https://gitlab.com/api/v4/projects/${project}/repository/archive.tar.gz?sha=${rev}")"
)
update_attr packages/minipro-rs/src.nix hash "$src_hash"

# The remaining hashes are fixed-output derivations: build, read the hash back
# from the mismatch message and assign it to the attribute of the failed
# derivation (npm-deps -> npmDepsHash, vendor-staging -> cargoHash).
log=$(mktemp)
trap 'rm -f "$log"' EXIT
for attr in minipro-rs-cli minipro-rs-gui; do
    ok=
    for _ in {1..3}; do
        if nix build --no-link ".#${attr}" >"$log" 2>&1; then
            echo "${attr}: build OK"
            ok=1
            break
        fi
        if ! grep -q 'hash mismatch in fixed-output derivation' "$log"; then
            cat "$log"
            exit 1
        fi
        got=$(grep -oE 'got: sha256-[A-Za-z0-9+/=]*' "$log" | sed -n 1p | cut -d' ' -f2)
        # Only the mismatch message names the failing derivation: the log also
        # lists derivations that built fine.
        failed=$(grep -oE "hash mismatch in fixed-output derivation '[^']+" "$log" |
            sed -nE 's,.*/nix/store/[^-]+-(.*)\.drv,\1,p' | sed -n 1p)
        if [[ ${failed} == minipro-rs-cli-*-vendor* ]]; then
            file=packages/minipro-rs/cli.nix
            hashattr=cargoHash
        elif [[ ${failed} == minipro-rs-gui-frontend-*-npm-deps ]]; then
            file=packages/minipro-rs/gui.nix
            hashattr=npmDepsHash
        elif [[ ${failed} == minipro-rs-gui-*-vendor* ]]; then
            file=packages/minipro-rs/gui.nix
            hashattr=cargoHash
        else
            echo "error: ${attr}: unexpected failing derivation: ${failed}" >&2
            cat "$log"
            exit 1
        fi
        echo "${attr}: updating ${hashattr} in ${file}"
        update_attr "$file" "$hashattr" "$got"
    done
    if [[ ! ${ok} ]]; then
        echo "error: ${attr}: hashes did not converge" >&2
        cat "$log"
        exit 1
    fi
done
