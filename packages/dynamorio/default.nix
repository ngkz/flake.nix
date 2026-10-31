# DynamoRIO dynamic instrumentation framework.
{
  cmake,
  fetchFromGitHub,
  lib,
  libunwind,
  lz4,
  makeWrapper,
  perl,
  snappy,
  stdenv,
  xxhash,
  zlib,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "dynamorio";
  version = "11.91.20756";

  src = fetchFromGitHub {
    owner = "DynamoRIO";
    repo = "dynamorio";
    rev = "cronbuild-${finalAttrs.version}";
    hash = "sha256-c2gYcajuxK1VG3wK5fP9Zb976iI0XY5/hVRK6P1cLgs=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [
    cmake
    makeWrapper
    perl
  ];

  buildInputs = [
    libunwind
    lz4
    snappy
    xxhash
    zlib
  ];

  cmakeFlags = [
    # The installation tree is DynamoRIO's runtime root: drrun, drconfig and
    # drdeploy take it as -root, resolve everything relative to it and write
    # per-application configuration into it.
    "-DCMAKE_INSTALL_PREFIX=${placeholder "out"}/opt/dynamorio"
    "-DBUILD_DOCS=OFF"
    "-DBUILD_PACKAGE=ON"
    "-DBUILD_TESTS=OFF"
    "-DDISABLE_FORMAT_CHECKS=ON"
    "-DVERSION_NUMBER=${finalAttrs.version}"
  ];

  # Only the 64-bit release core is built, so drdeploy's installation check
  # (tools/drdeploy.c, checked_files) warns about the missing
  # lib32/{debug,release} and lib64/debug cores on every run.  The warnings are
  # informational and the tools work; pass -quiet to silence them.  A debug core
  # needs -DDEBUG=ON with an empty CMAKE_BUILD_TYPE (CMakeLists.txt forces
  # DEBUG=OFF whenever the build type is set) and NIX_CFLAGS_COMPILE=-Wno-array-bounds,
  # because gcc flags the negative index in ext/drsyscall/drsyscall.c:1580.

  # DynamoRIO resolves its runtime relative to bin64 and lib64.
  dontMoveLib64 = true;

  # The frontends parse the installed objects with their own ELF loader, and
  # crash reporting resolves symbols from them (bin64/load_syms64.txt,
  # libdynamorio.so-gdb.py), so keep the files as the linker emitted them.
  dontStrip = true;

  postInstall = ''
    dynamorio=$out/opt/dynamorio

    # Runtime state directory, useless in the store.
    rm -rf "$dynamorio/logs"

    # genhtml and friends are Perl scripts with a hardcoded /usr/bin/perl.
    patchShebangs "$dynamorio/bin64" "$dynamorio/tools/bin64"

    # Keep the original layout intact: DynamoRIO resolves its runtime root
    # relative to the executable path.
    mkdir -p $out/bin

    # Expose all installed DynamoRIO frontends in the standard binary output.
    for program in "$dynamorio"/bin64/* "$dynamorio"/tools/bin64/*; do
      case "$program" in
        *.debug) continue ;;
      esac
      if [ -f "$program" ] && [ -x "$program" ]; then
        name=$(basename "$program")
        if [ ! -e "$out/bin/$name" ]; then
          # NixOS ships /lib64/ld-linux-x86-64.so.2 as the stub loader: a static
          # ELF without a PT_DYNAMIC.  DynamoRIO's private loader follows
          # libc.so.6's DT_NEEDED ld-linux-x86-64.so.2 through hard-coded system
          # directories and dies on it (module_get_os_privmod_data asserts
          # dyn != NULL).  LD_LIBRARY_PATH is searched before those directories,
          # so point it at the real loader.
          extra="--prefix LD_LIBRARY_PATH : ${stdenv.cc.libc}/lib"
          # The wrapped scripts reach Perl through PATH, the binaries do not.
          if head -n 1 "$program" | grep -q perl; then
            extra="$extra --prefix PATH : ${lib.makeBinPath [ perl ]}"
          fi
          # shellcheck disable=SC2086
          makeWrapper "$program" "$out/bin/$name" $extra
        fi
      fi
    done
  '';

  meta = {
    description = "Dynamic instrumentation tool platform";
    longDescription = ''
      DynamoRIO with the drrun, drconfig, drdeploy and drdisas frontends, the
      drcov, drcpusim, drmemtrace and drcachesim tools, and the sample clients.
    '';
    homepage = "https://dynamorio.org/";
    license = lib.licenses.bsd3;
    mainProgram = "drrun";
    platforms = lib.platforms.linux;
  };
})
