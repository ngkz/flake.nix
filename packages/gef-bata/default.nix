{
  lib,
  stdenv,
  fetchFromGitHub,
  makeWrapper,
  gdb,
  python3,
  binutils-all,
  file,
  ps,
  imagemagick,
  one_gadget,
  gcc,
  rp,
  bpftools,
  rubyPackages,
  colordiff,
  ceccomp,
  angr,
  coreutils, # cat, uname
  gnugrep, # grep
  util-linux, # column, hexdump
  less, # pager
  git, # git-diff
  tmux, # gef tmux-setup
  vmlinux-to-elf, # vmlinux-to-elf-apply
  magika-cli, # filetype-memory (the python magika module ships a CLI stub)
  lsb-release, # distro detection
  pkgsCross,
}:

let
  pythonEnv = python3.withPackages (
    ps:
    (with ps; [
      keystone-engine
      unicorn
      capstone
      ropper
      pillow
      pyzbar
      setuptools
      cffi
      gmpy2
    ])
    # XXX switch back to ps.angr after the nixpkgs build is fixed: 26.05 misses
    # setuptools-rust in the build environment, so the PEP 517 backend fails
    # https://github.com/NixOS/nixpkgs/issues/501379
    ++ [ angr ] # the flake-local angr suite (pkgs.ngkz.angr)
  );

  # gef.py looks up Return Point as `rp-lin`, but nixpkgs ships the rp++ 2.x
  # unified binary as `rp`.
  rpLin = stdenv.mkDerivation {
    pname = "gef-rp-lin";
    version = rp.version;

    dontUnpack = true;
    dontBuild = true;

    nativeBuildInputs = [ makeWrapper ];

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      makeWrapper ${lib.getExe rp} $out/bin/rp-lin
      runHook postInstall
    '';
  };

  # gef.py looks up cross compilers by their Debian prefix names when it builds
  # the BTF type objects of non-x86 kernels (`ktypes`). The wrappers exec the
  # original binaries, so the cc-wrapper still sees its own argv[0]. riscv32 is
  # left out on purpose: gef falls back to riscv64 with
  # -march=rv32imac -mabi=ilp32 when `riscv32-linux-gnu-gcc` is absent.
  crossGcc = stdenv.mkDerivation {
    pname = "gef-cross-gcc";
    version = gcc.version;

    dontUnpack = true;
    dontBuild = true;

    nativeBuildInputs = [ makeWrapper ];

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      makeWrapper ${lib.getExe pkgsCross.aarch64-multiplatform.buildPackages.gcc} $out/bin/aarch64-linux-gnu-gcc
      makeWrapper ${pkgsCross.armv7l-hf-multiplatform.buildPackages.gcc}/bin/armv7l-unknown-linux-gnueabihf-gcc $out/bin/arm-linux-gnueabihf-gcc
      makeWrapper ${lib.getExe pkgsCross.riscv64.buildPackages.gcc} $out/bin/riscv64-linux-gnu-gcc
      runHook postInstall
    '';
  };
in
stdenv.mkDerivation {
  pname = "gef-bata";
  version = "0-unstable-2026-10-09";

  src = fetchFromGitHub {
    owner = "bata24";
    repo = "gef";
    rev = "e0beaa443873a61c84120ae9277c7c58c1abafff";
    hash = "sha256-8BzHxsuVrnSGy5/Wqk1xEk3C7PO4qvXccBiOOlX1fbA=";
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
          binutils-all # cross-arch objdump/objcopy/nm/readelf/c++filt
          gcc
          crossGcc # aarch64/arm/riscv64 gcc for ktypes
          file
          ps
          imagemagick
          one_gadget
          rpLin # rp-lin alias of rp (rp++)
          ceccomp
          bpftools
          rubyPackages.seccomp-tools
          colordiff
          coreutils
          gnugrep
          util-linux
          less
          git
          tmux
          vmlinux-to-elf
          magika-cli
          lsb-release
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
