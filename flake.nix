{
  description = "ngkz public nix flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
    devshell.url = "github:numtide/devshell";
    devshell.inputs.nixpkgs.follows = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nixpkgs-unstable,
      flake-utils,
      ...
    }:
    {
      overlays = import ./overlays.nix inputs;
      homeModules = import ./home;
    }
    // flake-utils.lib.eachDefaultSystem (
      system:
      let
        cfg = (import ./nixpkgs.nix inputs) // {
          inherit system;
        };
        pkgs = import nixpkgs cfg;
      in
      {
        # devShells.<system>.default = pkgs.devshell.mkShell ...;
        devShells.default = pkgs.devshell.mkShell {
          imports = [ (pkgs.devshell.importTOML ./devshell.toml) ];
        };

        # packages.<system> = { <pkgname> = <derivation>, ... };
        packages = import ./packages {
          inherit pkgs;
          inherit inputs;
        };
      }
    );
}
