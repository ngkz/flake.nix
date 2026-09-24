# strixec CLI: write a fan-curve profile into the MS-S1 MAX EC table.
{
  lib,
  fetchFromGitHub,
  python3Packages,
  bash,
  lm_sensors,
}:
let
  inherit (import ./src.nix { inherit fetchFromGitHub; }) version src;
in
python3Packages.buildPythonApplication rec {
  pname = "strixec-cli";
  inherit version src;

  format = "other";

  # Scripts only use the standard library, there is nothing to test.
  doCheck = false;

  # strixec-findfan shells out to bash to load the CPUs and to sensors to read
  # Tctl next to the EC temperature register.
  makeWrapperArgs = [
    "--prefix PATH : ${
      lib.makeBinPath [
        bash
        lm_sensors
      ]
    }"
  ];

  installPhase = ''
    runHook preInstall

    install -Dm755 bin/strixec-setcurve -t $out/bin
    install -Dm755 bin/strixec-findfan -t $out/bin

    runHook postInstall
  '';

  meta = {
    description = "Apply fan-curve profiles to the Minisforum MS-S1 MAX embedded controller";
    homepage = "https://github.com/raimondomartire/ms-s1-max-fans-control";
    license = lib.licenses.gpl2Plus;
    mainProgram = "strixec-setcurve";
    platforms = [ "x86_64-linux" ];
  };
}
