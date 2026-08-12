{
  lib,
  stdenv,
  clang,
  llvm,
  fetchurl,
  fetchFromGitHub,
  linuxHeaders,
  python3,
  curl,
  which,
  ncurses,
  nix-update-script,
  debugRuntime ? true,
  runtimeAsserts ? false,
  extraKleeuClibcConfig ? { },
}:

let
  localeSrcBase = "uClibc-locale-030818.tgz";
  localeSrc = fetchurl {
    url = "http://www.uclibc.org/downloads/${localeSrcBase}";
    sha256 = "xDYr4xijjxjZjcz0YtItlbq5LwVUi7k/ZSmP6a+uvVc=";
  };
  resolvedExtraKleeuClibcConfig = lib.mapAttrsToList (name: value: "${name}=${value}") (
    extraKleeuClibcConfig
    // {
      "UCLIBC_DOWNLOAD_PREGENERATED_LOCALE_DATA" = "n";
      "RUNTIME_PREFIX" = "/";
      "DEVEL_PREFIX" = "/";
    }
  );
in
stdenv.mkDerivation (finalAttrs: {
  pname = "klee-uclibc";
  version = "1.4";
  src = fetchFromGitHub {
    owner = "klee";
    repo = "klee-uclibc";
    rev = "klee_uclibc_v${finalAttrs.version}";
    hash = "sha256-sogQK5Ed0k5tf4rrYwCKT4YRKyEovgT25p0BhGvJ1ok=";
  };

  nativeBuildInputs = [
    clang
    llvm
    python3
    curl
    which
  ];

  buildInputs = [ ncurses ];

  # The cc-wrapper provides glibc/ncurses/crt, but the ncurses configure probe
  # (plain `clang ... -lncurses`) doesn't resolve clang's own builtin headers
  # (stdbool.h etc.) from the resource dir automatically, so point at it.
  CPATH = "${clang.cc.lib}/lib/clang/16/include";

  # Some uClibc sources depend on Linux headers.
  UCLIBC_KERNEL_HEADERS = "${linuxHeaders}/include";

  # HACK: needed for cross-compile.
  # See https://www.mail-archive.com/klee-dev@imperial.ac.uk/msg03141.html
  # clang (a Nix cc-wrapper) needs the unwrapped clang's builtin headers
  # (resource dir) on the include path when emitting bitcode.
  KLEE_CFLAGS = "-idirafter ${clang.cc.lib}/lib/clang/16/include";

  prePatch = ''
    patchShebangs --build ./configure
    patchShebangs --build ./extra
  '';

  # klee-uclibc configure does not support --prefix, so we override configurePhase entirely.
  # Force the clang bitcode compiler. The Nix cc-wrapper (clang) finds glibc,
  # ncurses, crt and libgcc automatically; the CPATH above only adds clang's
  # own builtin headers, which its configure probe needs.
  configurePhase = ''
    ./configure ${
      lib.escapeShellArgs (
        [
          "--make-llvm-lib"
          "--with-cc"
          "${clang}/bin/clang"
        ]
        ++ lib.optional (!debugRuntime) "--enable-release"
        ++ lib.optional runtimeAsserts "--enable-assertions"
      )
    }

    # Set all the configs we care about.
    configs=(
      PREFIX=$out
    )
    for value in ${lib.escapeShellArgs resolvedExtraKleeuClibcConfig}; do
      configs+=("$value")
    done

    for configFile in .config .config.cmd; do
      for config in "''${configs[@]}"; do
        prefix="''${config%%=*}="
        if grep -q "$prefix" "$configFile"; then
          sed -i "s"'\001'"''${prefix}"'\001'"#''${prefix}"'\001'"g" "$configFile"
        fi
        echo "$config" >> "$configFile"
      done
    done
  '';

  # Link the locale source into the correct place
  preBuild = ''
    ln -sf ${localeSrc} extra/locale/${localeSrcBase}
  '';

  makeFlags = [ "HAVE_DOT_CONFIG=y" ];

  enableParallelBuilding = true;

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--version-regex"
      "v(\\d\\.\\d)"
    ];
  };

  meta = {
    description = "Modified version of uClibc for KLEE";
    longDescription = ''
      klee-uclibc is a bitcode build of uClibc meant for compatibility with the
      KLEE symbolic virtual machine.
    '';
    homepage = "https://github.com/klee/klee-uclibc";
    license = lib.licenses.lgpl3;
    maintainers = with lib.maintainers; [ numinit ];
  };
})
