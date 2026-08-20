# ghidra-cli - Rust CLI for automating Ghidra reverse engineering
{
  lib,
  fetchFromGitHub,
  ghidra,
  makeWrapper,
  openjdk21,
  openssl,
  pkg-config,
  rustPlatform,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "ghidra-cli";
  version = "0.2.2";

  src = fetchFromGitHub {
    owner = "akiselev";
    repo = "ghidra-cli";
    tag = "v${finalAttrs.version}";
    hash = "sha256-B4bnOOFtEsckT5TOAmjbx5AkrdpjeA248G+BrDUHY88=";
  };

  cargoHash = "sha256-r8AvlTJQ+j5YoLGJe3xIA0q+DPDTMKfhlT+nwFfNsPw=";

  nativeBuildInputs = [
    makeWrapper
    pkg-config
  ];

  buildInputs = [ openssl ];

  # Integration tests start Ghidra and require a writable project fixture.
  doCheck = false;

  postFixup = ''
    wrapProgram "$out/bin/ghidra" \
      --set-default GHIDRA_INSTALL_DIR "${ghidra}/lib/ghidra" \
      --set-default GHIDRA_CLI_JAVA_HOME "${openjdk21}"
  '';

  meta = {
    description = "Rust CLI for automating Ghidra headless reverse engineering and decompilation";
    homepage = "https://github.com/akiselev/ghidra-cli";
    license = lib.licenses.gpl3Only;
    mainProgram = "ghidra";
    platforms = ghidra.meta.platforms;
  };
})
