# minipro CLI: control XGecu TL866xx/T48/T56/T76 chip programmers.
# Pure-Rust USB through `nusb`, so no libusb at build or run time.
{
  lib,
  fetchFromGitLab,
  installShellFiles,
  rustPlatform,
}:
let
  inherit (import ./src.nix { inherit fetchFromGitLab; }) rev version src;
in
rustPlatform.buildRustPackage {
  pname = "minipro-rs-cli";
  inherit version src;

  # The workspace root Cargo.toml is a virtual manifest, so build the CLI
  # target by name; the minipro-core member is pulled in as its dependency.
  cargoBuildFlags = [
    "--bin"
    "minipro"
  ];
  cargoHash = "sha256-QcpgQP8BmwGyNPQ3X7yGTztRydLfiQ49FFAsIQIu/tk=";

  # minipro-core resolves the chip database through
  # option_env!("SHARE_INSTDIR"), so the store path is baked in at compile
  # time and no wrapper or MINIPRO_HOME is needed.
  SHARE_INSTDIR = "${placeholder "out"}/share/minipro-rs";

  nativeBuildInputs = [ installShellFiles ];

  postInstall = ''
    install -Dm644 ${src}/data/infoic.xml -t $out/share/minipro-rs
    install -Dm644 ${src}/data/logicic.xml -t $out/share/minipro-rs

    # Shell completions and man page. The binary regenerates them itself
    # (build.rs only writes them into OUT_DIR). `find` because the target
    # directory is triple-qualified when cross compiling.
    minipro=$(find target -type f -name minipro -perm -u+x | head -1)
    "$minipro" --generate-man >minipro.1
    installManPage minipro.1
    "$minipro" --generate-completions bash >minipro.bash
    "$minipro" --generate-completions zsh >_minipro
    "$minipro" --generate-completions fish >minipro.fish
    installShellCompletion minipro.bash _minipro minipro.fish
  '';

  meta = {
    description = "Chip programmer utility for XGecu TL866xx/T48/T56/T76";
    homepage = "https://gitlab.com/arcturus8081/minipro-rs";
    changelog = "https://gitlab.com/arcturus8081/minipro-rs/-/blob/${rev}/CHANGELOG.md";
    license = lib.licenses.gpl3Plus;
    mainProgram = "minipro";
    platforms = lib.platforms.linux;
  };
}
