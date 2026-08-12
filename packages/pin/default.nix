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
  version = "4.3";

  src = fetchurl {
    url = "https://software.intel.com/sites/landingpage/pintool/downloads/pin-external-4.3-99850-gce5652921-gcc-linux.tar.gz";
    sha256 = "0pmvlikxmfgr6xr3n74rk6bsbhrrppl92x182gr5n6mmpdd8vikl";
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

    # Fix Python shebangs
    substituteInPlace $out/opt/pin/source/tools/ImageTests/region_compare.py \
      --replace-fail '#!/usr/bin/python' '#!${python3}/bin/python'
    substituteInPlace $out/opt/pin/source/tools/SimpleExamples/callgraph.py \
      --replace-fail '#! /usr/bin/env python' '#!${python3}/bin/python'
    substituteInPlace $out/opt/pin/source/tools/SimpleExamples/flowgraph.py \
      --replace-fail '#! /usr/bin/env python' '#!${python3}/bin/python'

    # Fix Python shebangs in extras/libdwarf (not shipped in 3.31)
    substituteInPlace $out/opt/pin/extras/libdwarf/libdwarf-2.3.1/bugxml/readbugs.py \
      --replace-fail '#!/usr/bin/python3' '#!${python3}/bin/python3'
    substituteInPlace $out/opt/pin/extras/libdwarf/libdwarf-2.3.1/bugxml/bugrecord.py \
      --replace-fail '#!/usr/bin/python3' '#!${python3}/bin/python3'
    for f in \
      $out/opt/pin/extras/libdwarf/libdwarf-2.3.1/test/test_transformpath.py \
      $out/opt/pin/extras/libdwarf/libdwarf-2.3.1/test/test_dwarfdump.py \
      $out/opt/pin/extras/libdwarf/libdwarf-2.3.1/test/test_dwdiff.py \
      $out/opt/pin/extras/libdwarf/libdwarf-2.3.1/test/canonicalpath.py \
      $out/opt/pin/extras/libdwarf/libdwarf-2.3.1/tools/updatesemanticversion.py; do
      substituteInPlace "$f" \
        --replace-fail '#!/usr/bin/env python3' '#!${python3}/bin/python3'
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
