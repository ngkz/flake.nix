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
  unicorn,
  z3-solver,
}:
buildPythonPackage rec {
  # nixpkgs' z3-solver is a cmake build that installs the `z3` module without
  # any pip dist-info metadata. importlib.metadata (used by both the pypa/build
  # --no-isolation build-system check and the runtime deps check) can't resolve
  # a distribution with no metadata, so it reports "Missing dependencies:
  # z3-solver". z3-solver-meta adds a minimal .dist-info making it resolvable.
  # The dist-info name uses an underscore (z3_solver-<version>) rather than a
  # dash, matching nixpkgs' own packages: importlib indexes dist-info by the
  # text before the first dash, so a dash in the name would key it as "z3" and
  # never match a lookup for "z3-solver". z3-solver stays importable at build
  # time for setup.py's z3_loader(), which locates libz3 for the Rust z3-sys
  # extension.
  z3-solver-meta = z3-solver.overrideAttrs (old: {
    postInstall = (old.postInstall or "") + ''
      d="$python/lib/python3.13/site-packages/z3_solver-${old.version}.dist-info"
      mkdir -p "$d"
      printf 'Metadata-Version: 2.1\nName: z3-solver\nVersion: ${old.version}\n' > "$d/METADATA"
      : > "$d/RECORD"
    '';
  });
  pname = "angr";
  version = "10.0.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "angr";
    repo = "angr";
    tag = "v${version}";
    hash = "sha256-kv5s67+oyBQp/cqrnDPAEbanKHF3W5q+nMOLdMVF6hM=";
  };

  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit src;
    hash = "sha256-Hbwhxkks8WfP87Ggmq79Q/Kd+aWQHaI1to7Y9fT1azw=";
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
  #  - z3-solver==5.1.0.0 (nixpkgs has 4.16.0). angr/claripy use the z3
  #                    Python API (Solver/z3/smtlib) which is stable across
  #                    these releases.
  # pycparser~=3.0 is satisfied natively: nixpkgs ships pycparser 3.00.
  pythonRelaxDeps = [
    "capstone"
    "lmdb"
    "z3-solver"
  ];

  # The build-system pins protobuf>=6.31.1,<7 for grpcio-tools codegen, but
  # nixpkgs ships protobuf 7.x which works fine for code generation. Relax the
  # pin so setuptools doesn't reject the build environment.
  # z3-solver==5.1.0.0 is pinned in both build-system.requires and
  # dependencies, but nixpkgs ships 4.16.0. Relax the pin everywhere; the z3
  # Python API angr/claripy use is stable across these releases. nixpkgs' z3-
  # solver ships no dist-info metadata, so z3-solver-meta adds a minimal
  # .dist-info to make it resolvable by importlib.metadata (used by both the
  # pypa/build --no-isolation check and the runtime deps check).
  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace-fail '"protobuf>=6.31.1,<7"' '"protobuf"' \
      --replace-fail '"z3-solver==5.1.0.0"' '"z3-solver"'
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
    z3-solver-meta
    unicorn
  ];

  optional-dependencies = {
    angrdb = [ sqlalchemy ];
    unicorn = [ unicorn ];
  };

  setupPyBuildFlags = lib.optionals stdenv.hostPlatform.isLinux [
    "--plat-name"
    "linux"
  ];

  # Tests need angr binaries and extra deps (e.g. pypcode at runtime)
  doCheck = false;

  pythonImportsCheck = [
    "angr"
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
