{
  lib,
  stdenvNoCC,
  fetchurl,
}:
stdenvNoCC.mkDerivation rec {
  pname = "skk-dicts-jawiki";
  version = "2026.10.01.191227";

  src = fetchurl {
    url = "https://github.com/tokuhirom/jawiki-kana-kanji-dict/releases/download/v${version}/SKK-JISYO.jawiki";
    hash = "sha256-ENkjPsEoc5KVTcvweV7kdmjT5EREgRYn+S1jJhWmIIs=";
  };

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    install -D $src $out/share/skk/SKK-JISYO.jawiki
  '';

  meta = with lib; {
    description = "Japanese Wikipedia dictionary for SKK";
    homepage = "https://github.com/tokuhirom/jawiki-kana-kanji-dict";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
