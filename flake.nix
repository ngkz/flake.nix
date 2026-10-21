{
  description = "ngkz public nix flake";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixos-26.05/nixexprs.tar.zst";
    nixpkgs-unstable.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.zst";
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
      nixosModules = import ./nixos;
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

        checks = {
          overlayfs-tools = import ./packages/overlayfs-tools/vm-test.nix {
            inherit pkgs;
            ovl = self.packages.${system}.overlayfs-tools;
          };
          angr = import ./packages/angr/check.nix {
            inherit pkgs;
            angr = self.packages.${system}.angr;
          };
          klee = import ./packages/klee/check.nix {
            inherit pkgs;
            klee = self.packages.${system}.klee;
          };
        };
      }
    );
}
