{ nixpkgs-unstable, ... }@inputs:
rec {
  default = packages;

  packages = final: prev: {
    # make flake packages accessible through pkgs.ngkz.package
    ngkz = import ./packages {
      pkgs = final;
      inherit inputs;
    };
  };

  # Temporary fix for the nixos-26.05 jadx check phase failure, ported from
  # https://github.com/NixOS/nixpkgs/pull/580682. imageio's png tests fail with
  # "ValueError: Invalid mode for data type" under Python 3.13 and current
  # Pillow. quark-engine builds its own python scope and plotly and scikit-image
  # take imageio from it, so the fix is injected into that scope.
  # Drop once nixos-26.05 carries the fix.
  "jadx-temporary-fix" = final: prev: {
    jadx = prev.jadx.override {
      quark-engine = prev.quark-engine.override {
        python3Packages = prev.python3Packages.overrideScope (
          self: super: {
            imageio = super.imageio.overrideAttrs (old: {
              disabledTestPaths = old.disabledTestPaths ++ [
                # These tests require an older version of pillow
                "tests/test_pillow.py::test_png_16bit"
                "tests/test_pillow_legacy.py::test_png"
              ];
            });
          }
        );
      };
    };
  };

  # make nixos-unstable packages accessible through pkgs.unstable.package
  unstable = final: prev: {
    unstable = import nixpkgs-unstable {
      inherit (prev.stdenv.hostPlatform) system;
      inherit (prev) config;
    };
  };
}
