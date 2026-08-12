{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:
let
  srcinfo = import ./src.nix { inherit fetchFromGitHub; };
in
stdenvNoCC.mkDerivation {
  name = "px4_drv-udev-rules";

  inherit (srcinfo) version src;

  installPhase = ''
    install -Dm 644 ./etc/99-px4video.rules "$out/etc/udev/rules.d/99-px4video.rules"
  '';

  meta = with lib; {
    description = "udev rules for PLEX PX4/PX5/PX-MLT series ISDB-T/S receivers";
    license = licenses.free;
    platforms = platforms.linux;
  };
}
