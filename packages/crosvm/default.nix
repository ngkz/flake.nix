{
  lib,
  stdenv,
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

let
  # virtio-pvclock is only implemented for x86-64 and aarch64
  pvclockSupport = stdenv.hostPlatform.isx86_64 || stdenv.hostPlatform.isAarch64;
in
rustPlatform.buildRustPackage {
  pname = "crosvm";
  version = "0-unstable-2026-11-09";

  src = fetchgit {
    url = "https://chromium.googlesource.com/chromiumos/platform/crosvm";
    rev = "0faf7c37b981b55817b153b5dc157e15763c5e94";
    hash = "sha256-QMka/kTeUIykH0oEqhseUhE8i8qtgs6wwBfc6KnoGzQ=";
    fetchSubmodules = true;
  };

  separateDebugInfo = true;

  cargoHash = "sha256-if2T2y5l8zWW55RkCujClQwJeUSkUzZjOrP/WZ5xMsc=";

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

  buildFeatures = [ "virgl_renderer" ] ++ lib.optionals pvclockSupport [ "pvclock" ];

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
