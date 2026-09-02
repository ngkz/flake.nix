# LaurentZuijdwijk/llama.cpp fork — Vulkan/Qwen4Exp ROCmFPx branch
# https://github.com/LaurentZuijdwijk/llama.cpp
# Branch: vulkan/qwen4exp-rocmfpx (Vulkan-only, no ROCm)
{
  lib,
  cmake,
  fetchFromGitHub,
  installShellFiles,
  ninja,
  stdenv,

  openssl,
  pkg-config,
  shaderc,
  vulkan-headers,
  vulkan-loader,
}:

let
  inherit (lib)
    cmakeBool
    optionalString;

  vulkanBuildInputs = [
    shaderc
    vulkan-headers
    vulkan-loader
  ];
in
stdenv.mkDerivation (finalAttrs: {
  pname = "llama-cpp-laurent-qwen4exp-rocmfpx";
  version = "0-unstable-2026-08-31";

  outputs = [
    "out"
    "dev"
  ];

  src = fetchFromGitHub {
    owner = "LaurentZuijdwijk";
    repo = "llama.cpp";
    rev = "5e085d123eead2e89b5c19f824fccb05727da6a2";
    hash = "sha256-x09m31PDIPEFn8nenZIu0hsLZn2dblPTcMmKZoT3Qc4=";
    leaveDotGit = true;
    postFetch = ''
      git -C "$out" rev-parse --short HEAD > $out/COMMIT
      find "$out" -name .git -print0 | xargs -0 rm -rf
    '';
  };

  nativeBuildInputs = [
    cmake
    installShellFiles
    ninja
    pkg-config
  ];

  buildInputs = vulkanBuildInputs ++ [ openssl ];

  preConfigure = ''
    prependToVar cmakeFlags "-DLLAMA_BUILD_COMMIT:STRING=$(cat COMMIT)"
  '';

  cmakeFlags = [
    (cmakeBool "GGML_NATIVE" false)
    (cmakeBool "LLAMA_BUILD_EXAMPLES" false)
    (cmakeBool "LLAMA_BUILD_SERVER" true)
    (cmakeBool "LLAMA_BUILD_TESTS" false)
    (cmakeBool "LLAMA_BUILD_UI" false)
    (cmakeBool "LLAMA_OPENSSL" true)
    (cmakeBool "BUILD_SHARED_LIBS" true)
    (cmakeBool "GGML_VULKAN" true)
  ];

  postInstall = ''
    # Match previous binary name for this package
    ln -sf $out/bin/llama-cli $out/bin/llama

    mkdir -p $out/include
    cp $src/include/llama.h $out/include/

  ''
  + lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    installShellCompletion --cmd llama-server --bash <($out/bin/llama-server --completion-bash)
  '';

  doCheck = false;

  meta = {
    description = "llama.cpp with adaptive speculative decoding (--spec-draft-adaptive) and a Vulkan backend tuned for AMD Strix Halo. 4.7x on structured output, 1.9x mainline prefill on MoE.";
    homepage = "https://github.com/LaurentZuijdwijk/llama.cpp";
    license = lib.licenses.mit;
    mainProgram = "llama";
    platforms = lib.platforms.unix;
  };
})
