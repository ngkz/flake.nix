{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:
let
  srcinfo = import ./src.nix { inherit fetchFromGitHub; };
in
stdenvNoCC.mkDerivation {
  pname = "it930x-firmware";

  inherit (srcinfo) version src;

  installPhase = ''
    install -Dm 644 ./etc/it930x-firmware.bin "$out/lib/firmware/it930x-firmware.bin"
  '';

  meta = with lib; {
    description = "Firmware for PLEX PX4/PX5/PX-MLT series ISDB-T/S receivers";
    license = licenses.unfreeRedistributableFirmware;
    platforms = platforms.linux;
  };
}
