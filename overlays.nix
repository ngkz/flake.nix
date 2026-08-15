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

  # make nixos-unstable packages accessible through pkgs.unstable.package
  unstable = final: prev: {
    unstable = import nixpkgs-unstable {
      inherit (prev.stdenv.hostPlatform) system;
      inherit (prev) config;
    };
  };
}
