# angr - Powerful and user-friendly binary analysis platform
# Based on nixpkgs pkgs/development/python-modules/angr, bumped to 9.3.2.
# 9.3.2 pins the whole angr suite to 9.3.2, adds a Rust native extension
# (setuptools-rust), grpcio-tools protobuf codegen at build time, and new
# runtime deps (angr-data, lmdb, msgspec, platformdirs, pypcode,
# typing-extensions). ailment/cppheaderparser/dpkt/itanium-demangler/nampa/
# progressbar2/pyformlang/rpyc/unique-log-filter were dropped.
{
  lib,
  stdenv,
  buildPythonPackage,
  fetchFromGitHub,
  cargo,
  rustPlatform,
  rustc,
  setuptools,
  setuptools-rust,
  grpcio-tools,
  protobuf,
  # angr suite (pinned to 9.3.2)
  archinfo,
  claripy,
  cle,
  pyvex,
  angr-data,
  pypcode,
  # runtime deps
  cachetools,
  capstone,
  cffi,
  cxxheaderparser,
  gitpython,
  lmdb,
  msgspec,
  mulpyplexer,
  networkx,
  platformdirs,
  psutil,
  pycparser,
  pydemumble,
  rich,
  sortedcontainers,
  sympy,
  typing-extensions,
  sqlalchemy,
  unicorn-angr,
}:

buildPythonPackage rec {
  pname = "angr";
  version = "9.3.3";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "angr";
    repo = "angr";
    tag = "v${version}";
    hash = "sha256-00F2F8McL4JGWJzD9HjJoAFwMuGROMCN4ALh6qvaDgY=";
  };

  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit src;
    hash = "sha256-+yDP+7EAP2w5VSA1m/wuUEvB7NfCecmDZ8iqXiX8dHw=";
  };

  # Relax pinned versions nixpkgs doesn't carry at the exact pin:
  #  - capstone==5.0.9 (nixpkgs has 5.0.7)
  #  - lmdb==2.1.1     (nixpkgs has 1.7.5; nixpkgs builds py-lmdb against the
  #                    system liblmdb via LMDB_FORCE_SYSTEM=1, so the 2.1.1
  #                    security patches to the bundled lib don't apply. The
  #                    py-lmdb API angr uses — open/Environment/MapFullError/
  #                    Error — is unchanged across 1.x->2.x, and the 2.0
  #                    behavior changes (lock serialization, duplicate-path
  #                    rejection) don't affect angr's single-threaded temp-DB
  #                    usage.)
  # pycparser~=3.0 is satisfied natively: nixpkgs ships pycparser 3.00.
  pythonRelaxDeps = [
    "capstone"
    "lmdb"
  ];

  # The build-system pins protobuf>=6.31.1,<7 for grpcio-tools codegen, but
  # nixpkgs ships protobuf 7.x which works fine for code generation. Relax the
  # pin so setuptools doesn't reject the build environment.
  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace-fail '"protobuf>=6.31.1,<7"' '"protobuf"'
  '';

  build-system = [
    setuptools
    setuptools-rust
    grpcio-tools
    protobuf
    pyvex
  ];

  nativeBuildInputs = [
    rustPlatform.cargoSetupHook
    rustc
    cargo
  ];

  dependencies = [
    angr-data
    archinfo
    cachetools
    capstone
    cffi
    claripy
    cle
    cxxheaderparser
    gitpython
    lmdb
    msgspec
    mulpyplexer
    networkx
    platformdirs
    protobuf
    psutil
    pycparser
    pydemumble
    pypcode
    pyvex
    rich
    sortedcontainers
    sympy
    typing-extensions
  ];

  optional-dependencies = {
    angrdb = [ sqlalchemy ];
    unicorn = [ unicorn-angr ];
  };

  setupPyBuildFlags = lib.optionals stdenv.hostPlatform.isLinux [
    "--plat-name"
    "linux"
  ];

  # Tests need angr binaries and extra deps (e.g. pypcode at runtime)
  doCheck = false;

  pythonImportsCheck = [
    "angr"
    "claripy"
    "cle"
    "pyvex"
    "archinfo"
  ];

  meta = {
    description = "Powerful and user-friendly binary analysis platform";
    homepage = "https://angr.io/";
    license = lib.licenses.bsd2;
    platforms = lib.platforms.unix;
  };
}
