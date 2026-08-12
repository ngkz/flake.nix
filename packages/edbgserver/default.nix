# edbgserver, an eBPF-powered GDB server for Linux and Android
{
  lib,
  bpf-linker,
  fetchFromGitHub,
  rustPlatform,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "edbgserver";
  version = "1.2.1";

  src = fetchFromGitHub {
    owner = "Satar07";
    repo = "edbgserver";
    tag = "v${finalAttrs.version}";
    hash = "sha256-dfLh8dtjcrBhj7UgLdb7EFb4/Q5JOaoQLErnAmPr7qE=";
  };

  cargoHash = "sha256-zlfN6kgJcxo7Js4Geo1DIWCm6izIuFr95+Cib/FWr24=";

  nativeBuildInputs = [ bpf-linker ];

  cargoBuildFlags = [
    "--package"
    "edbgserver-cli"
  ];

  # aya-ebpf uses an unstable compiler feature and the Nix Rust toolchain does
  # not provide the rustup nightly toolchain requested by the upstream build.
  env.RUSTC_BOOTSTRAP = 1;

  # The upstream integration tests require privileged eBPF operations and use
  # a developer-specific absolute path.
  doCheck = false;

  meta = {
    description = "An eBPF-powered GDB server for Linux and Android";
    homepage = "https://github.com/Satar07/edbgserver";
    license = with lib.licenses; [
      mit
      asl20
      gpl2Only
    ];
    mainProgram = "edbgserver";
    platforms = [
      "aarch64-linux"
      "x86_64-linux"
    ];
  };
})
