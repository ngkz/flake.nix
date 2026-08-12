{
  lib,
  stdenv,
  fetchFromGitHub,
  kernel,
}:

let
  srcinfo = import ./src.nix { inherit fetchFromGitHub; };
in
stdenv.mkDerivation rec {
  pname = "px4_drv-module-${version}-${kernel.version}";
  inherit (srcinfo) version src;

  nativeBuildInputs = kernel.moduleBuildDependencies;

  sourceRoot = "${src.name}/driver";

  buildPhase = ''
    echo <<'EOS' >revision.h
      // revision.h

      #ifndef __REVISION_H__
      #define __REVISION_H__

      #define REVISION_NUMBER "1"
      #define REVISION_NAME   "tags/v${version}"
      #define COMMIT_HASH "${version}"

      #endif
    EOS
    make -C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build M=$PWD modules
  '';

  installPhase = ''
    install -D px4_drv.ko $out/lib/modules/${kernel.modDirVersion}/misc/px4_drv.ko
  '';

  meta = with lib; {
    description = "Unofficial Linux / Windows (WinUSB) driver for PLEX PX4/PX5/PX-MLT series ISDB-T/S receivers";
    license = licenses.gpl2;
    platforms = platforms.linux;
  };
}
