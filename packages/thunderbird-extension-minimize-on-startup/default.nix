{ lib, stdenvNoCC }:
stdenvNoCC.mkDerivation {
  pname = "thunderbird-extension-minimize-on-startup";
  version = "0.0.0";

  dontUnpack = true;
  dontPatch = true;
  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  installPhase = ''
    install -Dm644 ${./mas_aandrzej.com.xpi} $out/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/mas@aandrzej.com.xpi
  '';

  meta = with lib; {
    description = "Minimize Thunderbird window on startup";
    homepage = "https://services.addons.thunderbird.net/EN-us/thunderbird/addon/minimize-on-startup/";
    license = licenses.mpl20;
    platforms = platforms.unix;
  };
}
