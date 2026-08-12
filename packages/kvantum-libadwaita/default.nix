{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation rec {
  pname = "kvantum-libadwaita";
  version = "0-unstable-2025-09-13";

  src = fetchFromGitHub {
    owner = "GabePoel";
    repo = "KvLibadwaita";
    rev = "1f4e0bec44b13dabfa1fe4047aa8eeaccf2f3557";
    hash = "sha256-jCXME6mpqqWd7gWReT04a//2O83VQcOaqIIXa+Frntc=";
  };

  patchPhase = ''
    # red accent color
    # https://gnome.pages.gitlab.gnome.org/libadwaita/doc/1.7/css-variables.html
    # Background, Standalone (light), Standalone (dark)
    sed -i -e 's/#3584e4/#e62d42/g' \
           -e 's/#0461be/#c00023/g' \
           -e 's/#81d0ff/#ff888c/g' \
           src/KvLibadwaita/*
  '';

  installPhase = ''
    mkdir -p $out/share/Kvantum
    cp -r src/KvLibadwaita $out/share/Kvantum
  '';

  meta = with lib; {
    description = "Libadwaita style theme for Kvantum. Based on Colloid-kde.";
    homepage = "https://github.com/GabePoel/KvLibadwaita";
    license = licenses.gpl3;
    maintainers = [ ];
    platforms = platforms.all;
  };
}
