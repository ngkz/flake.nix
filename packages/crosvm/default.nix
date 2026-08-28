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
  version = "0-unstable-2026-08-28";

  src = fetchgit {
    url = "https://chromium.googlesource.com/chromiumos/platform/crosvm";
    rev = "307681e12d9aad81689f488203c9ef9dcdd5d68a";
    hash = "sha256-MWV52g/+ebiuyX/mCfcvhwTNeN/U5KujNGU6kNgfch0=";
    fetchSubmodules = true;
  };

  separateDebugInfo = true;

  cargoHash = "sha256-8NpYyCdG4DFQf2NzvKMwlk9hQUHTbZAZYHVIABqSahg=";

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
