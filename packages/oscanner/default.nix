# oscanner - Oracle assessment framework
{
  lib,
  stdenv,
  fetchurl,
  jre_headless,
  makeWrapper,
}:

stdenv.mkDerivation rec {
  pname = "oscanner";
  version = "1.0.6";

  src = fetchurl {
    url = "http://http.kali.org/pool/main/o/oscanner/oscanner_${version}.orig.tar.gz";
    hash = "sha256-/NV0x1asboU/d6l0eKO7qAYpBf8b7+bgpXXURnBuDIw=";
  };

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/oscanner
    # Drop Windows-only artifacts (exe/bat/jsmooth viewers)
    cp -r *.jar *.default *.conf *.txt oscanner.sh $out/share/oscanner/
    makeWrapper ${jre_headless}/bin/java $out/bin/oscanner \
      --chdir $out/share/oscanner \
      --add-flags "-cp .:ojdbc14.jar:java-getopt-1.0.9.jar:oscanner.jar:oracleplugins.jar:reportengine.jar ork.OracleScanner"
    runHook postInstall
  '';

  meta = {
    description = "Oracle assessment framework for SID enumeration and password testing";
    homepage = "http://www.cqure.net/wp/tools/database/oscanner/";
    license = lib.licenses.gpl2;
    mainProgram = "oscanner";
    platforms = lib.platforms.linux;
  };
}
