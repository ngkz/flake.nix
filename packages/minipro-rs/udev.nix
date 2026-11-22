# udev rules for the XGecu TL866xx/T48/T56/T76 programmers used by
# minipro-rs. Grants unprivileged access to the raw USB device nodes; wire
# it up with `services.udev.packages = [ minipro-rs-udev-rules ];`.
{
  lib,
  fetchFromGitLab,
  stdenvNoCC,
  udevCheckHook,
}:
let
  inherit (import ./src.nix { inherit fetchFromGitLab; }) rev version src;
in
stdenvNoCC.mkDerivation {
  pname = "minipro-rs-udev-rules";
  inherit version src;

  nativeBuildInputs = [ udevCheckHook ];
  doInstallCheck = true;

  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall

    install -Dm644 packaging/udev/60-minipro-rs.rules \
      $out/lib/udev/rules.d/60-minipro-rs.rules

    runHook postInstall
  '';

  meta = {
    description = "udev rules for the XGecu TL866xx/T48/T56/T76 chip programmers";
    homepage = "https://gitlab.com/arcturus8081/minipro-rs";
    changelog = "https://gitlab.com/arcturus8081/minipro-rs/-/blob/${rev}/CHANGELOG.md";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
