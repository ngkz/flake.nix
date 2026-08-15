#!/usr/bin/env bash
# Build and push all custom packages to Cachix

set -euo pipefail

cd "$PRJ_ROOT"

# Cachix cache name
CACHE="ngkz-flake-nix"

# Get auth token from secret-tool
CACHIX_AUTH_TOKEN=$(secret-tool lookup cachix "${CACHE}-token" || true)
if [ -z "$CACHIX_AUTH_TOKEN" ]; then
    echo "ERROR: CACHIX_AUTH_TOKEN not found in keyring"
    echo "  Run: secret-tool store --label='cachix ${CACHE} token' cachix ${CACHE}-token"
    exit 1
fi
export CACHIX_AUTH_TOKEN

# Get package names from flake
system=$(nix eval --impure --expr builtins.currentSystem 2>/dev/null | tr -d '"')
packages=$(nix flake show --json . 2>/dev/null | jq -r ".packages.\"$system\" | keys[]" | sort)

if [ -z "$packages" ]; then
    echo "No packages found"
    exit 1
fi

echo "Pushing $(echo "$packages" | wc -l) packages to $CACHE..."
echo ""

failed=0
for pkg in $packages; do
    if nix build --quiet --no-link --option warn-dirty false ".#$pkg" --print-out-paths |
        cachix push -m zstd -l 5 "$CACHE"; then
        echo -e "✓ $pkg OK"
    else
        echo -e "✗ $pkg FAILED"
        failed=$((failed + 1))
    fi
done

if [ "$failed" -gt 0 ]; then
    echo "FAILED: $failed package(s)"
    exit 1
fi

echo "All packages pushed successfully to $CACHE"
