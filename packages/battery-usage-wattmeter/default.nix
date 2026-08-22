{
  lib,
  stdenv,
  fetchFromGitHub,
  glib,
}:

stdenv.mkDerivation {
  pname = "gnome-shell-extension-battery-usage-wattmeter";
  version = "22";

  src = fetchFromGitHub {
    owner = "halfmexican";
    repo = "battery-usage-wattmeter-extension";
    rev = "41af852e4be7ba2a61ecca03e9fc397c64c462e3";
    hash = "sha256-SZHXcq088JE5fx1jAl1u1lvP5OWT3otcV3YvpOGv5X0=";
  };

  buildInputs = [ glib ];

  buildPhase = ''
    runHook preBuild
    make schemas
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/gnome-shell/extensions
    cp -r . $out/share/gnome-shell/extensions/battery-usage-wattmeter@halfmexicanhalfamazing.gmail.com
    runHook postInstall
  '';

  passthru = {
    extensionUuid = "battery-usage-wattmeter@halfmexicanhalfamazing.gmail.com";
    extensionPortalSlug = "battery-usage-wattmeter";
  };

  meta = with lib; {
    description = "Shows charging/discharging consumption (+/-) in Watt next to battery percentage level";
    homepage = "https://github.com/halfmexican/battery-usage-wattmeter-extension";
    license = licenses.gpl2Plus;
    platforms = platforms.linux;
  };
}
