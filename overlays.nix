{ nixpkgs-unstable, ... }@inputs:
{
  packages = final: prev: {
    # make flake packages accessible through pkgs.ngkz.package
    ngkz = import ./packages {
      pkgs = final;
      inherit inputs;
    };
  };

  # mutter 50.3 from PR #543345
  mutter-50_3 = final: prev: {
    mutter = final.callPackage ./packages/mutter_50_3.nix { };
  };

  # make nixos-unstable packages accessible through pkgs.unstable.package
  unstable = final: prev: {
    unstable = import nixpkgs-unstable {
      inherit (prev.stdenv.hostPlatform) system;
      inherit (prev) config;
    };
  };
}
