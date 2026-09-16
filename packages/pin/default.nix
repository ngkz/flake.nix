{
  autoPatchelfHook,
  binutils,
  fetchurl,
  lib,
  python3,
  stdenv,
}:
stdenv.mkDerivation {
  pname = "pin";
  version = "4.4";

  src = fetchurl {
    url = "https://software.intel.com/sites/landingpage/pintool/downloads/pin-external-4.4-99977-g54fbb8814-gcc-linux.tar.gz";
    sha256 = "0k534gsq0n1akq7cq465w94w5jbsnr4d3v99ixffll9bblx1hf1i";
  };

  buildInputs = [ stdenv.cc.cc.lib ];

  nativeBuildInputs = [
    autoPatchelfHook
    python3
  ];

  installPhase = ''
    # Install to /opt/pin keeping original directory structure
    mkdir -p $out/opt/pin
    cp -r ./* $out/opt/pin/

    # Symlink executables
    mkdir -p $out/bin
    ln -s $out/opt/pin/pin $out/bin/pin
    ln -s $out/opt/pin/intel64/bin/pinbin $out/bin/pinbin
    ln -s $out/opt/pin/intel64/bin/pindb $out/bin/pindb

    # Remove bundled libraries (use system ones instead)
    rm -rf $out/opt/pin/extras/xed-intel64/extlib
    rm -rf $out/opt/pin/intel64/runtime/cpplibs

    # Fix hardcoded paths
    substituteInPlace $out/opt/pin/source/tools/Config/unix.vars \
      --replace-fail '/usr/bin/ar' '${binutils}/bin/ar'

    # Fix python shebangs across all tools and libdwarf. Patch the
    # most specific patterns first so '#!/usr/bin/python3' is not
    # partially matched by '#!/usr/bin/python'.
    for f in $(find $out/opt/pin -name '*.py'); do
      substituteInPlace "$f" \
        --replace '#!/usr/bin/python3' '#!${python3}/bin/python3' \
        --replace '#!/usr/bin/python' '#!${python3}/bin/python' \
        --replace '#! /usr/bin/env python3' '#!${python3}/bin/python3' \
        --replace '#!/usr/bin/env python3' '#!${python3}/bin/python3' \
        --replace '#! /usr/bin/env python' '#!${python3}/bin/python' \
        --replace '#!/usr/bin/env python' '#!${python3}/bin/python' \
        --replace '#!/usr/intel/bin/python' '#!${python3}/bin/python'
    done
  '';

  preFixup = ''
    addAutoPatchelfSearchPath "$out/opt/pin/intel64/runtime/pincrt"
    addAutoPatchelfSearchPath "$out/opt/pin/extras/xed-intel64/lib"
  '';

  meta = {
    homepage = "https://www.intel.com/content/www/us/en/developer/articles/tool/pin-a-dynamic-binary-instrumentation-tool.html";
    description = "A tool for dynamic binary instrumentation";
    platforms = [ "x86_64-linux" ];
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
