{
  lib,
  pkgs,
  callPackage,
  fetchFromGitHub,
  cmake,
  python3,
  sqlite,
  gtest,
  lit,
  nix-update-script,

  # Build KLEE in debug mode. Defaults to false.
  debug ? false,

  # Include debug info in the build. Defaults to true.
  includeDebugInfo ? true,

  # Enable KLEE asserts. Defaults to true, since LLVM is built with them.
  asserts ? false,

  # Build the KLEE runtime in debug mode. Defaults to true, as this improves
  # stack traces of the software under test.
  debugRuntime ? true,

  # Enable runtime asserts. Default false.
  runtimeAsserts ? false,

  # Klee uclibc. Defaults to the bundled version.
  kleeuClibc ? null,

  # Extra klee-uclibc config for the default klee-uclibc.
  extraKleeuClibcConfig ? { },
}:

let
  # Vendored LLVM 16 toolchain (./llvm_16). KLEE doesn't support LLVM 18 yet, so
  # we build it against LLVM 16. This is nixpkgs 23.11's self-contained llvm/16
  # package definition; only the LLVM 16 source, patches and build code come from
  # the old nixpkgs, while all build tools (cmake, ninja, stdenv, ...) come from
  # the current nixpkgs.
  llvm_16 =
    let
      self = pkgs.callPackage ./llvm_16 {
        # LLVM 16 predates the current default GCC 15 and fails to build with it
        # (incompatible libstdc++ headers). Build with the still-available GCC 13
        # stdenv from the same (current) nixpkgs instead.
        stdenv = pkgs.gcc13Stdenv;
        # Only needed for cross-compilation wrappers we don't use.
        preLibcCrossHeaders = null;
        buildLlvmTools = self.tools;
        targetLlvmLibraries = self.libraries;
        targetLlvm = self.llvm;
      };
    in
    self;

  # A real Nix cc-wrapper around clang 16 so KLEE can compile its bitcode runtime
  # with full include/link support (glibc, ncurses, crt, libgcc) that raw clang
  # lacks. We use the unwrapped clang (no compiler-rt, which fails to build LLVM
  # 16 with current glibc) since KLEE builds itself with the regular stdenv. We
  # must point clang at its own resource dir so the runtime finds clang's builtin
  # headers (stddef.h, limits.h, ...).
  klee-clang = pkgs.wrapCCWith {
    cc = llvm_16.clang-unwrapped;
    extraBuildCommands = ''
      echo "-resource-dir=${llvm_16.clang-unwrapped.lib}/lib/clang/16" >> $out/nix-support/cc-cflags
    '';
  };

  stdenv = pkgs.gcc13Stdenv;
  clang = klee-clang;
  llvm = llvm_16.llvm;

  # KLEE links its C++ solver libs (z3/stp/cryptominisat) against the
  # gcc13-built LLVM 16, so they must be built with the same (gcc13) ABI;
  # otherwise the gcc15-built libs require newer libstdc++ symbols.
  z3 = pkgs.z3.override { stdenv = pkgs.gcc13Stdenv; };
  stp = pkgs.stp.override { stdenv = pkgs.gcc13Stdenv; };
  cryptominisat = pkgs.cryptominisat.override { stdenv = pkgs.gcc13Stdenv; };

  # The chosen version of klee-uclibc.
  chosenKleeuClibc =
    if kleeuClibc == null then
      callPackage ./klee-uclibc.nix {
        inherit
          stdenv
          clang
          llvm
          extraKleeuClibcConfig
          debugRuntime
          runtimeAsserts
          ;
      }
    else
      kleeuClibc;

  # Python used for KLEE tests.
  kleePython = python3.withPackages (ps: with ps; [ tabulate ]);
in
# KLEE doesn't support LLVM 18 yet (see nixpkgs), so we build it against the
# vendored LLVM 16 toolchain (packages/llvm_16). We use the regular stdenv to
# build KLEE itself; clang 16 is only needed to compile the bitcode runtime.
stdenv.mkDerivation (finalAttrs: {
  pname = "klee";
  version = "3.2";

  src = fetchFromGitHub {
    owner = "klee";
    repo = "klee";
    tag = "v${finalAttrs.version}";
    hash = "sha256-8DofxLyTV8Al7ys8vSJpzf6qQV3sw940lGIZBvZqe2c=";
  };

  nativeBuildInputs = [ cmake ];

  buildInputs = [
    llvm
    cryptominisat
    sqlite
    stp
    z3
  ];

  nativeCheckInputs = [
    gtest

    # Should appear BEFORE lit, since lit passes through python rather
    # than the python environment we make.
    kleePython
    (lit.override { python = kleePython; })
  ];

  cmakeBuildType =
    if debug then
      "Debug"
    else if !debug && includeDebugInfo then
      "RelWithDebInfo"
    else
      "MinSizeRel";

  cmakeFlags =
    let
      onOff = val: if val then "ON" else "OFF";
    in
    [
      "-DKLEE_RUNTIME_BUILD_TYPE=${if debugRuntime then "Debug" else "Release"}"
      "-DLLVMCC=${clang}/bin/clang"
      "-DLLVMCXX=${clang}/bin/clang++"
      "-DKLEE_ENABLE_TIMESTAMP=${onOff false}"
      "-DKLEE_UCLIBC_PATH=${chosenKleeuClibc}"
      "-DENABLE_KLEE_ASSERTS=${onOff asserts}"
      "-DENABLE_POSIX_RUNTIME=${onOff true}"
      "-DENABLE_UNIT_TESTS=${onOff true}"
      "-DENABLE_SYSTEM_TESTS=${onOff true}"
      # TCMalloc (gperftools) detection is broken; it's an optional allocator
      # optimization, so disable it.
      "-DENABLE_TCMALLOC=OFF"
      "-DLIT_ARGS=--verbose"
      "-DGTEST_SRC_DIR=${gtest.src}"
      "-DGTEST_INCLUDE_DIR=${gtest.src}/googletest/include"
      "-Wno-dev"
    ];

  # Silence various warnings during the compilation of fortified bitcode.
  env.NIX_CFLAGS_COMPILE = toString [ "-Wno-macro-redefined" ];

  env.FILECHECK_OPTS = "--dump-input-filter=all";

  prePatch = ''
    patchShebangs --build .
  '';

  # https://github.com/klee/klee/issues/1690
  hardeningDisable = [ "fortify" ];

  enableParallelBuilding = true;
  doCheck = true;

  passthru = {
    updateScript = nix-update-script {
      extraArgs = [
        "--version-regex"
        "v(\\d\\.\\d)"
      ];
    };
    # Let the user access the chosen uClibc outside the derivation.
    uclibc = chosenKleeuClibc;
  };

  __structuredAttrs = true;

  meta = {
    mainProgram = "klee";
    description = "Symbolic virtual machine built on top of LLVM";
    longDescription = ''
      KLEE is a symbolic virtual machine built on top of the LLVM compiler
      infrastructure. Currently, there are two primary components:

      1. The core symbolic virtual machine engine; this is responsible for
         executing LLVM bitcode modules with support for symbolic values. This
         is comprised of the code in lib/.

      2. A POSIX/Linux emulation layer oriented towards supporting uClibc, with
         additional support for making parts of the operating system environment
         symbolic.

      Additionally, there is a simple library for replaying computed inputs on
      native code (for closed programs). There is also a more complicated
      infrastructure for replaying the inputs generated for the POSIX/Linux
      emulation layer, which handles running native programs in an environment
      that matches a computed test input, including setting up files, pipes,
      environment variables, and passing command line arguments.
    '';
    homepage = "https://klee.github.io";
    license = lib.licenses.ncsa;
    platforms = [ "x86_64-linux" ];
    maintainers = with lib.maintainers; [ numinit ];
  };
})
