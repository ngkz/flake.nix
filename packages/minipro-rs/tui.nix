# minipro-tui: terminal UI for the XGecu TL866xx/T48/T56/T76 chip programmers.
# Ratatui front-end over the same minipro-core library the CLI uses, so the
# pure-Rust USB stack needs no libusb.
{
  lib,
  fetchFromGitLab,
  rustPlatform,
}:
let
  inherit (import ./src.nix { inherit fetchFromGitLab; }) rev version src;
in
rustPlatform.buildRustPackage {
  pname = "minipro-rs-tui";
  inherit version src;

  # minipro-tui is a member of the repo root workspace, so build its binary
  # by name; minipro-core comes in as its dependency.
  cargoBuildFlags = [
    "--bin"
    "minipro-tui"
  ];
  # Same workspace and Cargo.lock as cli.nix, hence the identical vendor hash.
  cargoHash = "sha256-Evz7xh/cp+8aZAD3IWTanfdp0nN6pEsQbtV3YsrNTIU=";
  # Skip the core/CLI unit tests, they are covered by the CLI package.
  cargoTestFlags = [
    "--bin"
    "minipro-tui"
  ];

  # minipro-core resolves the chip database through
  # option_env!("SHARE_INSTDIR"), so the store path is baked in at compile
  # time and no wrapper or MINIPRO_HOME is needed.
  SHARE_INSTDIR = "${placeholder "out"}/share/minipro-rs";

  postInstall = ''
    install -Dm644 ${src}/data/infoic.xml -t $out/share/minipro-rs
    install -Dm644 ${src}/data/logicic.xml -t $out/share/minipro-rs
  '';

  meta = {
    description = "Terminal UI for the XGecu TL866xx/T48/T56/T76 chip programmers";
    homepage = "https://gitlab.com/arcturus8081/minipro-rs";
    changelog = "https://gitlab.com/arcturus8081/minipro-rs/-/blob/${rev}/CHANGELOG.md";
    license = lib.licenses.gpl3Plus;
    mainProgram = "minipro-tui";
    platforms = lib.platforms.linux;
  };
}
