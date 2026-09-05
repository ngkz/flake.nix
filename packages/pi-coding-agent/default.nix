{
  lib,
  buildNpmPackage,
  fetchzip,
  nix-update-script,
  versionCheckHook,
  writableTmpDirAsHomeHook,
  ripgrep,
  makeBinaryWrapper,
}:
buildNpmPackage (finalAttrs: {
  pname = "pi-coding-agent";
  version = "0.85.0";

  src = fetchzip {
    url = "https://github.com/earendil-works/pi/releases/download/v${finalAttrs.version}/pi-${finalAttrs.version}-source.tar.gz";
    hash = "sha256-UVOAsKLb661PI3Q1WtJnzkSyI/UBUuBmYUeLLTJsu88=";
  };

  npmDepsHash = "sha256-K/KiukwTHwu4HE8hUu7ur3bxggwfO0WL+QDI0FtxP3I=";

  npmWorkspace = "packages/coding-agent";

  # Skip native module rebuild for unneeded workspaces (e.g. canvas from web-ui)
  npmRebuildFlags = [ "--ignore-scripts" ];

  nativeBuildInputs = [
    makeBinaryWrapper
  ];

  # Build workspace dependencies in order using npm workspaces,
  # then the coding-agent. Matching npm run build:offline.
  buildPhase = ''
    runHook preBuild

    # Build workspace deps in order (matching npm run build:offline)
    npm run build --workspace=packages/tui
    npm run build --workspace=packages/telemetry
    npm run build:offline --workspace=packages/ai
    npm run build --workspace=packages/chord
    npm run build --workspace=packages/agent
    npm run build --workspace=packages/protocol
    npm run build --workspace=packages/server
    npm run build --workspace=packages/client
    npm run build --workspace=packages/coding-agent

    runHook postBuild
  '';

  # npm workspace symlinks in the output point into packages/ which
  # doesn't exist there. Replace runtime deps with built content and
  # delete the rest.
  postInstall = ''
    local nm="$out/lib/node_modules/pi-monorepo/node_modules"

    # Replace workspace deps needed at runtime with real copies
    for ws in @earendil-works/pi-telemetry:packages/telemetry \
              @earendil-works/pi-ai:packages/ai \
              @earendil-works/chord:packages/chord \
              @earendil-works/pi-server:packages/server \
              @earendil-works/pi-agent-core:packages/agent \
              @earendil-works/pi-tui:packages/tui \
              @earendil-works/pi-protocol:packages/protocol \
              @earendil-works/pi-client:packages/client; do
      IFS=: read -r pkg src <<< "$ws"
      rm "$nm/$pkg"
      cp -r "$src" "$nm/$pkg"
    done

    # Delete remaining workspace symlinks
    find "$nm" -type l -lname '*/packages/*' -delete

    # Clean up now-dangling .bin symlinks
    find "$nm/.bin" -xtype l -delete
  '';
  postFixup = "wrapProgram $out/bin/pi --prefix PATH : ${lib.makeBinPath [ ripgrep ]}";

  doInstallCheck = true;
  nativeInstallCheckInputs = [
    writableTmpDirAsHomeHook
    versionCheckHook
  ];
  versionCheckKeepEnvironment = [ "HOME" ];
  versionCheckProgram = "${placeholder "out"}/bin/pi";
  versionCheckProgramArg = "--version";

  meta = {
    description = "Coding agent CLI with read, bash, edit, write tools and session management";
    homepage = "https://pi.dev";
    downloadPage = "https://www.npmjs.com/package/@earendil-works/pi-coding-agent";
    changelog = "https://github.com/badlogic/pi-mono/blob/main/packages/coding-agent/CHANGELOG.md";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ munksgaard ];
    mainProgram = "pi";
  };
})
