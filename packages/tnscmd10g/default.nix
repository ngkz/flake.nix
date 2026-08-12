# tnscmd10g - Oracle TNS listener access tool
{
  lib,
  stdenv,
  fetchurl,
  perl,
  makeWrapper,
}:

stdenv.mkDerivation rec {
  pname = "tnscmd10g";
  version = "1.3";

  src = fetchurl {
    url = "http://http.kali.org/pool/main/t/tnscmd10g/tnscmd10g_${version}.orig.tar.gz";
    hash = "sha256-I1EuQszoJhrMoo8rzGSQ9nssBKhTfhoNrx1sV56G+50=";
  };

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/libexec $out/bin
    install -m 0555 tnscmd10g $out/libexec/tnscmd10g
    makeWrapper ${perl}/bin/perl $out/bin/tnscmd10g \
      --add-flags "$out/libexec/tnscmd10g"
    runHook postInstall
  '';

  meta = {
    description = "Lame tool to prod the Oracle TNS listener process on 1521/tcp";
    homepage = "https://www.jammed.com/~jwa/hacks/security/tnscmd/tnscmd-doc.html";
    license = lib.licenses.gpl2Only;
    mainProgram = "tnscmd10g";
    platforms = lib.platforms.linux;
  };
}
