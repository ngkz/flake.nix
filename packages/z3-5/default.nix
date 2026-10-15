# z3 5.1 built with this (stable) package set from the nixpkgs-unstable recipe.
#
# angr 10 vendors its solver bridge in Rust (native/clarirs-z3 + z3-sys), which links
# libz3 directly and bakes the z3 5.x Z3_decl_kind numbering into its bindings
# (Z3_OP_UNINTERPRETED = 49167). nixpkgs stable ships z3 4.16, where the same constant is
# 45102, so every symbol read back from a solver model hits the "unknown decl kind"
# branch and angr can no longer produce solutions. angr pins z3-solver==5.1.0.0 for this
# reason. nixpkgs-unstable has z3 5.1.0 but its binaries need glibc 2.43, so rebuild
# the same recipe here.
#
# No update script: the version follows the nixpkgs-unstable flake input (see
# scripts/update.sh).
{
  pkgs,
  z3-unstable,
}:
pkgs.callPackage (z3-unstable + /pkgs/by-name/z3/z3/package.nix) { }
