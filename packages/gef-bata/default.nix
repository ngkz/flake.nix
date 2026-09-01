{
  lib,
  stdenv,
  fetchFromGitHub,
  makeWrapper,
  gdb,
  python3,
  bintools-unwrapped,
  file,
  ps,
  imagemagick,
  one_gadget,
  gcc,
  rp,
  bpftools,
  rubyPackages,
  colordiff,
  codext,
}:

let
  pythonEnv = python3.withPackages (
    pkgs: with pkgs; [
      keystone-engine
      unicorn
      capstone
      ropper
      tqdm
      codext
      # XXX broken in nixpkgs 26.05: missing setuptools-rust and mismatched angr package versions https://github.com/NixOS/nixpkgs/issues/501379
      # angr
      pillow
      pyzbar
      setuptools
      crccheck
      cffi
      gmpy2
    ]
  );
in
stdenv.mkDerivation {
  pname = "gef-bata";
  version = "0-unstable-2026-09-01";

  src = fetchFromGitHub {
    owner = "bata24";
    repo = "gef";
    rev = "d6fb283ff17d6d8fda2225be47466e870d16abef";
    hash = "sha256-ON2G51M4wS3NZhZ/OFiVgZU6UtY0NMi65ptXOHfMxdM=";
  };

  dontBuild = true;

  nativeBuildInputs = [
    makeWrapper
  ];

  installPhase = ''
    mkdir -p $out/share/gef
    cp gef.py $out/share/gef
    makeWrapper ${gdb}/bin/gdb $out/bin/gef \
      --add-flags "-q -x $out/share/gef/gef.py" \
      --set NIX_PYTHONPATH ${pythonEnv}/${python3.sitePackages} \
      --prefix PATH : ${
        lib.makeBinPath [
          pythonEnv
          bintools-unwrapped # for readelof
          gcc
          file
          ps
          imagemagick
          one_gadget
          rp
          bpftools
          rubyPackages.seccomp-tools
          colordiff
        ]
      }
  '';

  meta = {
    description = "Modern experience for GDB with advanced debugging features for exploit developers & reverse engineers (bata24 fork)";
    mainProgram = "gef";
    homepage = "https://github.com/bata24/gef";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
    maintainers = with lib.maintainers; [ freax13 ];
  };
}
