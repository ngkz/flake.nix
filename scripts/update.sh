#!/usr/bin/env bash
set -eu -o pipefail

cd "$PRJ_ROOT"

# Ensure GITHUB_TOKEN for gh api
if [[ -z "${GH_TOKEN:-}" && -z "${GITHUB_TOKEN:-}" ]]; then
    token=$(secret-tool lookup service gh:github.com || true)
    if [[ -n "$token" ]]; then
        export GITHUB_TOKEN="$token"
    fi
fi

nix flake update --no-warn-dirty
for updater in packages/*/update.sh; do
    "$updater"
done
