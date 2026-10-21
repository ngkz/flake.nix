#!/usr/bin/env bash
# Run flake checks: all checks when called without arguments, otherwise the
# named checks from this flake's checks.<system> attribute set

set -euo pipefail

cd "$PRJ_ROOT"

if [ "$#" -eq 0 ]; then
    exec nix flake check -L
fi

system=$(nix eval --raw --impure --expr 'builtins.currentSystem')

targets=()
for check in "$@"; do
    # Quote the check name so that names with dots keep working
    targets+=(".#checks.${system}.\"${check}\"")
done

exec nix build --rebuild -L --no-link "${targets[@]}"
