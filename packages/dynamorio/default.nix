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
  version = "11.91.20672";

  src = fetchFromGitHub {
    owner = "DynamoRIO";
    repo = "dynamorio";
    rev = "cronbuild-${finalAttrs.version}";
    hash = "sha256-x5V0egd6KuhLwL7h+N5wi8isG2+njMQJGzpgI7BTVzs=";
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
    "-DCMAKE_INSTALL_PREFIX=${placeholder "out"}/opt/dynamorio"
    "-DBUILD_DOCS=OFF"
    "-DBUILD_PACKAGE=ON"
    "-DBUILD_TESTS=OFF"
    "-DDISABLE_FORMAT_CHECKS=ON"
    "-DVERSION_NUMBER=${finalAttrs.version}"
  ];

  # DynamoRIO resolves its runtime relative to bin64 and lib64.
  dontMoveLib64 = true;
  separateDebugInfo = true;

  postInstall = ''
    dynamorio=$out/opt/dynamorio

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
          makeWrapper "$program" "$out/bin/$name"
        fi
      fi
    done
  '';

  meta = {
    description = "Dynamic instrumentation tool platform";
    homepage = "https://dynamorio.org/";
    license = lib.licenses.bsd3;
    mainProgram = "drrun";
    platforms = lib.platforms.linux;
  };
})
