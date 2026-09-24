# strixec GUI: editable fan curve, live CPU temperature, profile applying.
{
  lib,
  fetchFromGitHub,
  python3Packages,
  qt6,
  polkit,
  copyDesktopItems,
  makeDesktopItem,
  strixec-cli,
}:
let
  inherit (import ./src.nix { inherit fetchFromGitHub; }) version src;

  icon = "share/icons/hicolor/scalable/apps/strixec-fan.svg";

  desktopItem = makeDesktopItem {
    name = "strixec-gui";
    desktopName = "MS S1 Max fans control";
    comment = "Fan control for Minisforum MS-S1 MAX";
    exec = "strixec-gui";
    icon = "strixec-fan";
    terminal = false;
    categories = [
      "System"
      "Settings"
      "HardwareSettings"
    ];
  };
in
python3Packages.buildPythonApplication rec {
  pname = "strixec-gui";
  inherit version src;

  format = "other";

  # The app has no test suite.
  doCheck = false;

  nativeBuildInputs = [
    qt6.wrapQtAppsHook
    copyDesktopItems
  ];

  desktopItems = [ desktopItem ];

  # QT_PLUGIN_PATH for the plugins: qtbase for the platform plugin, qtsvg for
  # the SVG window icon.
  buildInputs = [
    qt6.qtbase
    qt6.qtsvg
  ];

  pythonPath = [ python3Packages.pyside6 ];

  postPatch = ''
    substituteInPlace bin/strixec-gui \
      --replace-fail '"/usr/local/bin/strixec-setcurve"' '"${strixec-cli}/bin/strixec-setcurve"' \
      --replace-fail '"/usr/local/share/strixec/strixec-fan.svg"' '"${placeholder "out"}/${icon}"'
  '';

  installPhase = ''
    runHook preInstall

    install -Dm755 bin/strixec-gui -t $out/bin
    install -Dm644 share/strixec-fan.svg "$out/${icon}"

    runHook postInstall
  '';

  # wrapQtAppsHook only wraps ELF binaries, so hand its arguments to the
  # wrapper wrapPythonPrograms generates for this Python script. The pkexec
  # directory is appended, not prepended: pkexec must be setuid, and NixOS
  # lists its own wrapper directory (/run/wrappers/bin) first in PATH.
  preFixup = ''
    makeWrapperArgs+=("--suffix" "PATH" ":" "${lib.makeBinPath [ polkit ]}")
    makeWrapperArgs+=("''${qtWrapperArgs[@]}")
  '';

  meta = {
    description = "Fan control GUI for the Minisforum MS-S1 MAX";
    homepage = "https://github.com/raimondomartire/ms-s1-max-fans-control";
    license = lib.licenses.gpl2Plus;
    mainProgram = "strixec-gui";
    platforms = [ "x86_64-linux" ];
  };
}
