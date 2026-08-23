# 参考にした実装

# - asosnovsky/nixos-setup/pkgs/ds4/default.nix — パラメータ化されたバックエンド切り替え方式
# - hellas-ai/nix-strix-halo/pkgs/ds4-rocm/ — カスタム fork 方式
# - antirez/ds4/STRIXHALO.md — Strix Halo 用のビルド手順
{
  lib,
  stdenv,
  fetchFromGitHub,
  makeWrapper,
  curl,
  cacert,
  rocmPackages,
}:

# DwarfStar 4 (antirez/ds4) — a from-source DeepSeek V4 Flash/PRO local inference
# engine optimized for AMD Strix Halo (gfx1151) via ROCm.
#
# Upstream is a hand-written Makefile with no `install` target and no tagged
# releases, so we pin a `main` commit and write our own installPhase.

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
  pname = "ds4-rocm";
  version = "0-unstable-2026-08-23";

  src = fetchFromGitHub {
    owner = "antirez";
    repo = "ds4";
    rev = "c1d4597a80e300b803dc642519718f2c999589da";
    hash = "sha256-kKvcLQ5vhte441+D81VkZRPbbe6VMi6bJKGcqL2uSEQ=";
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
    description = "DeepSeek V4 Flash/PRO local inference engine (DwarfStar) — ROCm/Strix Halo build";
    homepage = "https://github.com/antirez/ds4";
    license = lib.licenses.mit;
    sourceProvenance = [ lib.sourceTypes.fromSource ];
    platforms = lib.platforms.linux;
    mainProgram = "ds4";
  };
})
