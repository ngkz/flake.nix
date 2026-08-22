# ROCmFPX - AMD-focused GGUF quant formats fork of llama.cpp
# https://github.com/charlie12345/ROCmFPX
# strix-rocmfp4-mtp build
{
  lib,
  cmake,
  fetchFromGitHub,
  installShellFiles,
  stdenv,
  bash,

  rocmPackages,

  pkg-config,
  openssl,
  shaderc,
  vulkan-headers,
  vulkan-loader,
}:

let
  inherit (lib)
    cmakeBool
    cmakeFeature
    optionals
    optionalString
    ;

  rocmBuildInputs = with rocmPackages; [
    clr
    hipblas
    rocblas
  ];

  vulkanBuildInputs = [
    shaderc
    vulkan-headers
    vulkan-loader
  ];
in
stdenv.mkDerivation {
  pname = "llama-cpp-rocmfpx-strix-mtp";
  version = "0-unstable-2026-08-22";

  src = fetchFromGitHub {
    owner = "charlie12345";
    repo = "ROCmFPX";
    rev = "c49ebdbd5c9f01ec242369f9e7f7967855f80cba";
    hash = "sha256-FBS0vMkDg+1k6gwhp/SpYLBvqZHciIfIxUF19OBIRpc=";
  };

  nativeBuildInputs = [
    bash
    cmake
    installShellFiles
    pkg-config
  ];

  buildInputs = rocmBuildInputs ++ vulkanBuildInputs ++ [ openssl ];

  configurePhase = "true";

  buildPhase = ''
    patchShebangs scripts/

    # Disable tests and avoid embedding build RPATH into binaries
    sed -i \
      -e 's/-DLLAMA_BUILD_TESTS=ON/-DLLAMA_BUILD_TESTS=OFF/' \
      -e 's/-DGGML_BUILD_TESTS=OFF/& \\\n    -DLLAMA_TESTS_INSTALL=OFF \\\n    -DGGML_BUILD_INSTALL=OFF \\\n    -DLLAMA_BUILD_EXAMPLES=OFF \\\n    -DCMAKE_SKIP_BUILD_RPATH=ON \\\n    -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON/' \
      scripts/build-strix-rocmfp4-mtp.sh

    export CMAKE_HIP_COMPILER="${rocmPackages.clr.hipClangPath}/clang++"
    scripts/build-strix-rocmfp4-mtp.sh llama-cli \
                                       llama-server \
                                       llama-completion \
                                       llama-quantize \
                                       llama-bench \
                                       llama-perplexity
  '';

  installPhase = ''
    mkdir -p $out/bin $out/lib $out/include

    # Install binaries that were actually built
    cp build-strix-rocmfp4/bin/llama-cli $out/bin/
    cp build-strix-rocmfp4/bin/llama-server $out/bin/
    cp build-strix-rocmfp4/bin/llama-completion $out/bin/
    cp build-strix-rocmfp4/bin/llama-quantize $out/bin/
    cp build-strix-rocmfp4/bin/llama-bench $out/bin/
    cp build-strix-rocmfp4/bin/llama-perplexity $out/bin/

    # Symlink for compatibility
    ln -sf $out/bin/llama-cli $out/bin/llama

    # Install shared libraries
    cp build-strix-rocmfp4/bin/lib*.so* $out/lib/
  ''
  + lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    installShellCompletion --cmd llama-server --bash <($out/bin/llama-server --completion-bash)
  '';

  doCheck = false;

  meta = {
    description = "llama.cpp fork with AMD-focused ROCmFPX GGUF quant formats";
    homepage = "https://github.com/charlie12345/ROCmFPX";
    license = lib.licenses.mit;
    mainProgram = "llama";
    platforms = lib.platforms.unix;
  };
}
