# umap2 - USB Host Security Assessment Tool (python2)
#
# nixpkgs python2 toolchain is largely unmaintained: its requests/urllib3 deps
# are broken for py2 and every dep's test phase pulls pytest. Build umap2 in a
# python2 scope that (a) disables checks and (b) overrides the broken deps with
# vendored py2-compatible versions from nixos-20.09 (see ./python), copied from
# ~/misc/nixpkgs.
{
  lib,
  python27,
}:

let
  python2-vintage = python27.pkgs.overrideScope (
    final: prev: {
      buildPythonPackage = args: prev.buildPythonPackage (args // { doCheck = false; });
      buildPythonApplication = args: prev.buildPythonApplication (args // { doCheck = false; });
      buildPythonModule = args: prev.buildPythonModule (args // { doCheck = false; });
      six = final.callPackage ./python/six.nix { };
      requests = final.callPackage ./python/requests.nix { };
      urllib3 = final.callPackage ./python/urllib3.nix { };
      chardet = final.callPackage ./python/chardet.nix { };
      idna = final.callPackage ./python/idna.nix { };
      certifi = final.callPackage ./python/certifi.nix { };
      bitarray = final.callPackage ./python/bitarray.nix { };
      bitstring = final.callPackage ./python/bitstring.nix { };
      docopt = final.callPackage ./python/docopt.nix { };
      pyserial = final.callPackage ./python/pyserial.nix { };
    }
  );

  kittyfuzzer = python2-vintage.callPackage ./kittyfuzzer.nix { };
in
python2-vintage.callPackage ./umap2.nix {
  inherit kittyfuzzer;
}
