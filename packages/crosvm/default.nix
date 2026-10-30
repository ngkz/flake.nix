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
  version = "0-unstable-2026-10-29";

  src = fetchgit {
    url = "https://chromium.googlesource.com/chromiumos/platform/crosvm";
    rev = "c99b49ea939234503d664fdc429ddd0923cae33b";
    hash = "sha256-nvOW4aI3hJdx/x9zGSX0avDtquGvae3JEJWoZSvdrZ4=";
    fetchSubmodules = true;
  };

  separateDebugInfo = true;

  cargoHash = "sha256-6pcJIIL2OK9vPzjyey9oHXdIZUsTjfaEOK0SGeUfNiw=";

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
