# DS4FA (julianmb/ds4fa) — a tuned gfx1151 fork of antirez/ds4 with ROCmFPX
# tooling, SSD expert streaming, and native DeepSeek-V4-Flash-0731 support.
{
  lib,
  stdenv,
  fetchFromGitHub,
  makeWrapper,
  curl,
  cacert,
  rocmPackages,
}:

let
  # ROCm libraries the gfx1151 backend needs.
  rocmInputs = [
    rocmPackages.clr # provides hipcc + HIP runtime
    rocmPackages.hipblas
    rocmPackages.hipblas-common # hipblas.h includes hipblas-common/hipblas-common.h
    rocmPackages.hipblaslt
    rocmPackages.rocblas
    rocmPackages.rocwmma # gfx1151 backend uses rocWMMA headers
    rocmPackages.hipcub
    rocmPackages.rocprim
    rocmPackages.rocthrust
    rocmPackages.rocm-runtime
  ];

  # -L<dir> and matching rpath so the linked binaries resolve the ROCm .so's
  # from the store at runtime (upstream assumes /opt/rocm on PATH).
  rocmLibDirs = map (p: "${lib.getLib p}/lib") rocmInputs;
  rocmLinkFlags = lib.concatStringsSep " " (map (d: "-L${d} -Wl,-rpath,${d}") rocmLibDirs);
  rocmIncludeFlags = lib.concatStringsSep " " (map (p: "-I${lib.getDev p}/include") rocmInputs);
in
stdenv.mkDerivation (finalAttrs: {
  pname = "ds4fa";
  version = "0-unstable-2026-08-21";

  src = fetchFromGitHub {
    owner = "julianmb";
    repo = "ds4fa";
    rev = "ab64ea135f6ce1991988840e8ce97d64f3545d91";
    hash = "sha256-XXVtVTPjEbHhIoWBNnWEgtu4rWuhFEqx9bGksJ0TJ8E=";
  };

  enableParallelBuilding = true;

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = rocmInputs;

  # ROCm compiler flags (hipcc is the raw ROCm compiler, not the nix cc-wrapper,
  # so it needs explicit -I for headers from the store).
  ROCM_CFLAGS = "-O3 -ffast-math -g -fno-finite-math-only -pthread -D__HIP_PLATFORM_AMD__ -Wno-unused-command-line-argument --offload-arch=gfx1151 ${rocmIncludeFlags}";
  ROCM_LDLIBS = "-lm -pthread ${rocmLinkFlags} -lhipblas -lhipblaslt";

  buildPhase = ''
    runHook preBuild

    # Build all binaries with ROCm backend for Strix Halo (gfx1151)
    make strix-halo \
      ROCM_ARCH=gfx1151 \
      ROCM_CFLAGS="$ROCM_CFLAGS" \
      ROCM_LDLIBS="$ROCM_LDLIBS" \
      -j"$NIX_BUILD_CORES"

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 -t "$out/bin" ds4 ds4-server ds4-bench ds4-eval ds4-agent

    # Wire upstream's GGUF downloader in as `ds4-download-model`. Patch its
    # project-root detection so the gguf dir and the `ds4flash.gguf` symlink
    # land in a writable location ($DS4_HOME, default: cwd) instead of the
    # read-only store dir that `dirname $0` would resolve to here.
    install -Dm755 download_model.sh "$out/bin/ds4-download-model"
    substituteInPlace "$out/bin/ds4-download-model" \
      --replace-fail 'ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)' 'ROOT=''${DS4_HOME:-$PWD}' \
      --replace-warn './download_model.sh' 'ds4-download-model'
    runHook postInstall
  '';

  # `ds4-download-model` shells out to curl (and optionally the `hf` CLI for the
  # huge PRO files); make curl available and point it at a CA bundle if the
  # environment doesn't already set one.
  postFixup = ''
    wrapProgram "$out/bin/ds4-download-model" \
      --prefix PATH : ${lib.makeBinPath [ curl ]} \
      --set-default SSL_CERT_FILE ${cacert}/etc/ssl/certs/ca-bundle.crt
  '';

  meta = {
    description = "DeepSeek V4 Flash/PRO local inference engine (DwarfStar) — ROCmFPX/Strix Halo fork";
    homepage = "https://github.com/julianmb/ds4fa";
    license = lib.licenses.mit;
    sourceProvenance = [ lib.sourceTypes.fromSource ];
    platforms = lib.platforms.linux;
    mainProgram = "ds4";
  };
})
