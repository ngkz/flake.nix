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
  version = "0-unstable-2026-08-26";

  src = fetchgit {
    url = "https://chromium.googlesource.com/chromiumos/platform/crosvm";
    rev = "80371a49faf7b1971601a3d26bbd33f586ea8e68";
    hash = "sha256-2oNioRO6IKkA6jiX2LrWBzggxUrEMUfIJ2mVneWm6Ts=";
    fetchSubmodules = true;
  };

  separateDebugInfo = true;

  cargoHash = "sha256-CM0N3A09kH+g/4/Gu8Ouun11w0wbOracnPG6/vNdUMY=";

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
