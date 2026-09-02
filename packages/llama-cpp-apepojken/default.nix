# apepojken/llama.cpp fork — Qwen4Exp spec-decoding with MTP branch
# https://github.com/apepojken/llama.cpp
# Branch: qwen4exp-spec-mtp
{
  lib,
  cmake,
  fetchFromGitHub,
  installShellFiles,
  ninja,
  stdenv,

  openssl,
  pkg-config,
  rocmPackages,
  shaderc,
  vulkan-headers,
  vulkan-loader,
}:
let
  inherit (lib) cmakeBool cmakeFeature optionalString;

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
stdenv.mkDerivation (finalAttrs: {
  pname = "llama-cpp-apepojken";
  version = "0-unstable-2026-08-31";

  outputs = [
    "out"
    "dev"
  ];

  src = fetchFromGitHub {
    owner = "apepojken";
    repo = "llama.cpp";
    rev = "843d5750579a15ed4a42d73eb862855c271021ac";
    hash = "sha256-EBhndkzJGSgqAPoMR0UFBKsKIarEywipIaeMTzYxWZU=";
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

  buildInputs = rocmBuildInputs ++ vulkanBuildInputs ++ [ openssl ];

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
    (cmakeBool "GGML_HIP" true)
    (cmakeBool "GGML_VULKAN" true)
  ]
  ++ [
    (cmakeFeature "CMAKE_HIP_COMPILER" "${rocmPackages.clr.hipClangPath}/clang++")
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
    description = "llama.cpp fork with Qwen4Exp spec-decoding and multi-token prediction (MTP)";
    homepage = "https://github.com/apepojken/llama.cpp";
    license = lib.licenses.mit;
    mainProgram = "llama";
    platforms = lib.platforms.unix;
  };
})
