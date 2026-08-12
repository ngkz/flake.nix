{ lib, fetchFromGitHub }:

fetchFromGitHub rec {
  owner = "thep0y";
  repo = "fcitx5-themes-candlelight";
  rev = "60aeaddfb3ecdb6a132e8da7569a6c442e6bb217";
  sha256 = "sha256-ZHGf/Urd91Nysjza8R2aKNWvX6/dSWEv8M5+ItCy3Yw=";
  name = "${repo}-${builtins.substring 0 6 rev}";

  postFetch = ''
    mkdir -p $out/share/fcitx5/themes
    mv $out/{autumn,green,spring,summer,transparent-green,winter} $out/share/fcitx5/themes
    shopt -s extglob dotglob
    rm -rf $out/!(share)
    shopt -u extglob dotglob
  '';

  meta = with lib; {
    description = "Colorful Fcitx5 themes inspired by candlelight";
    homepage = "https://github.com/thep0y/fcitx5-themes-candlelight";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
