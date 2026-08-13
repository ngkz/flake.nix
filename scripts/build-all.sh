#!/usr/bin/env bash
# Build-test all custom packages in this flake

set -euo pipefail

cd "$PRJ_ROOT"

# Get package names from flake
system=$(nix eval --impure --expr builtins.currentSystem 2>/dev/null | tr -d '"')
packages=$(nix flake show --json . 2>/dev/null | jq -r ".packages.\"$system\" | keys[]" | sort)

if [ -z "$packages" ]; then
    echo "No packages found"
    exit 1
fi

echo "Building $(echo "$packages" | wc -l) packages..."
echo ""

failed=0
for pkg in $packages; do
    if nix build --quiet --no-link --option warn-dirty false ".#$pkg"; then
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

echo "All packages built successfully"
