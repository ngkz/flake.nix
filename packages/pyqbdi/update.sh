#!/usr/bin/env bash
# Update QBDI and its CMake-pinned source archives.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

pname=pyqbdi
owner=QBDI
repo=QBDI

current=$(sed -n 's/^  version = "\(.*\)";/\1/p' default.nix)
latest_tag=$(gh api "repos/$owner/$repo/releases/latest" --jq '.tag_name')
latest=${latest_tag#v}

if [[ $current == "$latest" ]]; then
    echo "$pname is up-to-date: $latest"
    exit 0
fi

source_hash=$(nix-prefetch-github --json "$owner" "$repo" --rev "$latest_tag" | jq -r .hash)

cmake_dependencies=$(mktemp)
llvm_dependencies=$(mktemp)
trap 'rm -f "$cmake_dependencies" "$llvm_dependencies"' EXIT
curl -fsSL "https://raw.githubusercontent.com/$owner/$repo/$latest_tag/cmake/QBDIDependencies.cmake" >"$cmake_dependencies"
curl -fsSL "https://raw.githubusercontent.com/$owner/$repo/$latest_tag/cmake/llvm/QBDI_llvm.cmake" >"$llvm_dependencies"

spdlog_version=$(sed -n 's/^set(SPDLOG_VERSION \([^)]*\)).*/\1/p' "$cmake_dependencies")
spdlog_hash=$(grep -o 'SHA256=[0-9a-f]*' "$cmake_dependencies" | head -n1 | cut -d= -f2)
pybind11_version=$(sed -n 's#.*github.com/pybind/pybind11/archive/v\([^"/]*\)\.zip.*#\1#p' "$cmake_dependencies")
pybind11_hash=$(sed -n '/pybind11\/archive/,/EXCLUDE_FROM_ALL/ s/.*SHA256=\([0-9a-f]*\).*/\1/p' "$cmake_dependencies")
llvm_version=$(sed -n 's/^set(QBDI_LLVM_VERSION \([^)]*\)).*/\1/p' "$llvm_dependencies")
llvm_hashes=$(grep -o 'SHA256=[0-9a-f]*' "$llvm_dependencies" | cut -d= -f2)
llvm_cmake_hash=$(printf '%s\n' "$llvm_hashes" | sed -n '1p')
llvm_source_hash=$(printf '%s\n' "$llvm_hashes" | sed -n '2p')

hash_to_sri() {
    nix hash to-sri --type sha256 "$1"
}

sed -i "s/^  version = \"$current\";/  version = \"$latest\";/" default.nix
sed -i "/owner = \"$owner\";/,/};/ s/hash = \".*\";/hash = \"$source_hash\";/" default.nix

spdlog_sri=$(hash_to_sri "$spdlog_hash")
pybind11_sri=$(hash_to_sri "$pybind11_hash")
llvm_cmake_sri=$(hash_to_sri "$llvm_cmake_hash")
llvm_source_sri=$(hash_to_sri "$llvm_source_hash")
sed -i \
    -e "/spdlog-archive = fetchurl {/,/};/ s#url = \".*\";#url = \"https://github.com/gabime/spdlog/archive/refs/tags/v${spdlog_version}.zip\";#" \
    -e "/spdlog-archive = fetchurl {/,/};/ s#hash = \".*\";#hash = \"$spdlog_sri\";#" \
    -e "/pybind11-archive = fetchurl {/,/};/ s#url = \".*\";#url = \"https://github.com/pybind/pybind11/archive/v${pybind11_version}.zip\";#" \
    -e "/pybind11-archive = fetchurl {/,/};/ s#hash = \".*\";#hash = \"$pybind11_sri\";#" \
    -e "/llvm-src-archive = fetchurl {/,/};/ s#url = \".*\";#url = \"https://github.com/llvm/llvm-project/releases/download/llvmorg-${llvm_version}/llvm-${llvm_version}.src.tar.xz\";#" \
    -e "/llvm-src-archive = fetchurl {/,/};/ s#hash = \".*\";#hash = \"$llvm_source_sri\";#" \
    -e "/llvm-cmake-archive = fetchurl {/,/};/ s#url = \".*\";#url = \"https://github.com/llvm/llvm-project/releases/download/llvmorg-${llvm_version}/cmake-${llvm_version}.src.tar.xz\";#" \
    -e "/llvm-cmake-archive = fetchurl {/,/};/ s#hash = \".*\";#hash = \"$llvm_cmake_sri\";#" \
    -e "s/llvm-[0-9.]*\\.src\\.tar\\.xz/llvm-${llvm_version}.src.tar.xz/g" \
    -e "s/cmake-[0-9.]*\\.src\\.tar\\.xz/cmake-${llvm_version}.src.tar.xz/g" \
    -e "s#pybind11_download/v[0-9.]*\\.zip#pybind11_download/v${pybind11_version}.zip#g" \
    default.nix

printf '%s updated: %s -> %s\n' "$pname" "$current" "$latest"
