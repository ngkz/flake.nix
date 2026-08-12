{
  lib,
  stdenvNoCC,
  fetchurl,
}:
stdenvNoCC.mkDerivation rec {
  pname = "skk-dicts-jawiki";
  version = "2026.08.01.150202";

  src = fetchurl {
    url = "https://github.com/tokuhirom/jawiki-kana-kanji-dict/releases/download/v${version}/SKK-JISYO.jawiki";
    hash = "sha256-UcmvRD7cZh3SjXgZ5F4Gj4lQD/LiX/6p5ZyG+3mI48Q=";
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
