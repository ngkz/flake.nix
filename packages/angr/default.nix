# angr - Powerful and user-friendly binary analysis platform
# Based on nixpkgs pkgs/development/python-modules/angr, bumped to the 10.x
# series. 10.x pins the angr suite (archinfo, cle, pyvex) to its own version,
# builds a Rust native extension (setuptools-rust, with claripy merged in),
# generates angr/protos/*_pb2.py with grpcio-tools at build time, and needs
# z3 5.x (see packages/z3-5) plus angr-data, lmdb, msgspec, platformdirs,
# pypcode, pydemumble, cxxheaderparser at runtime. sympy, dpkt, itanium-demangler,
# nampa, progressbar2, pyformlang, rpyc, unique-log-filter, ailment are gone.
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
  typing-extensions,
  sqlalchemy,
  unicorn,
  z3-solver,
}:
buildPythonPackage rec {
  # The z3 cmake build installs the `z3` module without any pip dist-info
  # metadata. importlib.metadata (used by both the pypa/build --no-isolation
  # build-system check and the runtime deps check) can't resolve a distribution
  # with no metadata, so it reports "Missing dependencies: z3-solver".
  # z3-solver-meta adds a minimal .dist-info making it resolvable.
  # The dist-info name uses an underscore (z3_solver-<version>) rather than a
  # dash, matching nixpkgs' own packages: importlib indexes dist-info by the
  # text before the first dash, so a dash in the name would key it as "z3" and
  # never match a lookup for "z3-solver". z3-solver stays importable at build
  # time for setup.py's z3_loader(), which locates libz3 for the Rust z3-sys
  # extension.
  z3-solver-meta = z3-solver.overrideAttrs (old: {
    postInstall = (old.postInstall or "") + ''
      for sp in "$python"/lib/python*/site-packages; do
        d="$sp/z3_solver-${old.version}.dist-info"
        mkdir -p "$d"
        printf 'Metadata-Version: 2.1\nName: z3-solver\nVersion: ${old.version}\n' > "$d/METADATA"
        : > "$d/RECORD"
      done
    '';
  });
  pname = "angr";
  version = "10.0.5";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "angr";
    repo = "angr";
    tag = "v${version}";
    hash = "sha256-memxffALYmcDNm1MgzgBom+5FNFKI4ympOJvY/NsHAg=";
  };

  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit src;
    hash = "sha256-rlztS1GC5GCBHdr9VaeGNOp5ni0qcA8ot1RSJlXFuMI=";
  };

  # Relax pinned versions nixpkgs doesn't carry at the exact pin:
  #  - capstone==5.0.9 (nixpkgs has 5.0.7)
  #  - lmdb==3.0.0     (nixpkgs has 1.7.5; nixpkgs builds py-lmdb against the
  #                    system liblmdb via LMDB_FORCE_SYSTEM=1, so the 2.x/3.x
  #                    security patches to the bundled lib don't apply. The
  #                    py-lmdb API angr uses — open/Environment/MapFullError/
  #                    Error — is unchanged across 1.x->3.x, and the 2.0
  #                    behavior changes (lock serialization, duplicate-path
  #                    rejection) don't affect angr's single-threaded temp-DB
  #                    usage.)
  #  - cachetools>=7,<8 (nixpkgs has 6.2.4; angr only uses LRUCache(maxsize=)
  #                    and its evict= callback, both present since 5.3.)
  #  - z3-solver==5.3.1.0 (packages/z3-5 provides z3 5.1.0; the pin only uses
  #                    the 4-segment PyPI version scheme). z3 5 is a hard
  #                    requirement: angr's vendored Rust solver bridge links
  #                    libz3 directly and bakes the z3 5.x Z3_decl_kind
  #                    numbering, so the suite fails at runtime on z3 4.x.
  #                    5.1.0 satisfies the 5.x contract: checks.angr solves a
  #                    crackme through the solver bridge with it.
  #  - pycparser~=3.11.0 (nixpkgs has 3.00; 3.11 adds C11 parsing features on
  #                    top of the unchanged 3.x c_parser/c_ast API angr uses).
  pythonRelaxDeps = [
    "cachetools"
    "capstone"
    "lmdb"
    "pycparser"
    "z3-solver"
  ];

  # build-system.requires pins z3-solver to an exact 4-segment PyPI version
  # ("5.3.1.0" = z3 5.3.1), which the relax hook does not touch: it only edits
  # project.dependencies. Strip the pin by pattern, so a version bump that raises
  # the z3 pin does not fail the build. The z3 build ships no dist-info
  # metadata, so z3-solver-meta adds a minimal .dist-info to make it resolvable
  # by importlib.metadata (used by both the pypa/build --no-isolation check and
  # the runtime deps check).
  postPatch = ''
    sed -i -E 's/"z3-solver==[0-9.]+"/"z3-solver"/g' pyproject.toml
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
