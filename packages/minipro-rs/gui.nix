# MINIPRO-RS desktop GUI: Tauri 2 + Svelte 5 front-end for the same
# minipro-core chip-programmer library the CLI uses.
{
  lib,
  buildNpmPackage,
  cargo-tauri,
  fetchFromGitLab,
  jq,
  pkg-config,
  rustPlatform,
  # WebKitGTK 4.1 stack (GTK3 based)
  glib-networking,
  gtk3,
  libappindicator-gtk3,
  librsvg,
  libsoup_3,
  openssl,
  webkitgtk_4_1,
  wrapGAppsHook3,
}:
let
  inherit (import ./src.nix { inherit fetchFromGitLab; }) version src;

  rustSubdir = "gui/src-tauri";

  # Svelte front-end. Built separately so the Rust build only embeds a store
  # path and never needs node.
  frontend = buildNpmPackage {
    pname = "minipro-rs-gui-frontend";
    inherit version src;

    sourceRoot = "${src.name}/gui";
    npmBuildScript = "build";
    npmDepsHash = "sha256-6Nm2l1zXlAInOzTqGZHVgbpgiALIU4d3hDcLx/Hqih8=";

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      cp -r dist/* $out/

      runHook postInstall
    '';

    dontFixup = true;
  };
in
rustPlatform.buildRustPackage {
  pname = "minipro-rs-gui";
  inherit version src;

  # The GUI is its own cargo workspace, excluded from the repo root one.
  cargoRoot = rustSubdir;
  buildAndTestSubdir = rustSubdir;
  doCheck = false; # src-tauri has no tests
  cargoHash = "sha256-V44gv2xL8jrXsaWNAjiqPQc2gUMqnggv8BCizCX2atA=";

  nativeBuildInputs = [
    cargo-tauri.hook
    jq
    pkg-config
    rustPlatform.bindgenHook
    wrapGAppsHook3
  ];

  buildInputs = [
    glib-networking
    gtk3
    libappindicator-gtk3
    librsvg
    libsoup_3
    openssl
    webkitgtk_4_1
  ];

  postPatch = ''
    # Point the bundler at the pre-built front-end and drop the npm hook.
    jq '.build.frontendDist = "${frontend}" | del(.build.beforeBuildCommand)' \
      gui/src-tauri/tauri.conf.json >gui/src-tauri/tauri.conf.json.tmp
    mv gui/src-tauri/tauri.conf.json.tmp gui/src-tauri/tauri.conf.json
  '';

  # Same database baked in as for the CLI: cargo-tauri.hook unpacks the .deb
  # bundle into $out, which places the resources in $out/lib/<productName>.
  SHARE_INSTDIR = "${placeholder "out"}/lib/MINIPRO-RS-GUI";

  meta = {
    description = "GUI for the XGecu TL866xx/T48/T56/T76 chip programmers";
    homepage = "https://gitlab.com/arcturus8081/minipro-rs";
    changelog = "https://gitlab.com/arcturus8081/minipro-rs/-/blob/v${version}/CHANGELOG.md";
    license = lib.licenses.gpl3Plus;
    mainProgram = "minipro-gui";
    platforms = lib.platforms.linux;
  };
}
