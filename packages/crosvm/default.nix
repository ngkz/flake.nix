{
  lib,
  rustPlatform,
  fetchgit,
  pkg-config,
  protobuf,
  python3,
  wayland-scanner,
  libcap,
  libdrm,
  libepoxy,
  minijail,
  virglrenderer,
  wayland,
  wayland-protocols,
}:

rustPlatform.buildRustPackage {
  pname = "crosvm";
  version = "0-unstable-2026-07-23";

  src = fetchgit {
    url = "https://chromium.googlesource.com/chromiumos/platform/crosvm";
    rev = "2205c9e9fff48358e11a4e83e000fcfb32e1763a";
    hash = "sha256-IYd9U+rXXv82cVvXnMMGe3i4EulmfJA9U3lXK9IZnho=";
    fetchSubmodules = true;
  };

  separateDebugInfo = true;

  cargoHash = "sha256-kt0D11teSGerXIJXZ25KnBRkt+h1XyB9gQ/ykkzcHwU=";

  nativeBuildInputs = [
    pkg-config
    protobuf
    python3
    rustPlatform.bindgenHook
    wayland-scanner
  ];

  buildInputs = [
    libcap
    libdrm
    libepoxy
    minijail
    virglrenderer
    wayland
    wayland-protocols
  ];

  preConfigure = ''
    patchShebangs third_party/minijail/tools/*.py
  '';

  env = {
    CROSVM_USE_SYSTEM_MINIGBM = true;
    CROSVM_USE_SYSTEM_VIRGLRENDERER = true;
  };

  buildFeatures = [ "virgl_renderer" ];

  meta = {
    description = "Secure virtual machine monitor for KVM";
    homepage = "https://crosvm.dev/";
    mainProgram = "crosvm";
    maintainers = with lib.maintainers; [ qyliss ];
    license = lib.licenses.bsd3;
    platforms = [
      "aarch64-linux"
      "riscv64-linux"
      "x86_64-linux"
    ];
  };
}
