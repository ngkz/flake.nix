{
  lib,
  stdenv,
  fetchFromGitHub,
  attr,
  meson,
  ninja,
  pkg-config,
  python3,
  sudo,
}:

stdenv.mkDerivation rec {
  pname = "overlayfs-tools";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "kmxz";
    repo = "overlayfs-tools";
    rev = "42582352e11b162895c06826f18a2246d8005ca9";
    hash = "sha256-ZNNA5jxFM/0o4mzyObR7mwcLBQ8PvF/hljpZDcOOA3g=";
  };

  doCheck = false;

  # meson.build requires setfattr at configure time (find_program)
  nativeBuildInputs = [
    attr
    meson
    ninja
    pkg-config
    python3
    sudo
  ];

  meta = with lib; {
    description = "Maintenance tools for overlay-filesystem";
    homepage = "https://github.com/kmxz/overlayfs-tools";
    license = licenses.wtfpl;
    platforms = platforms.linux;
  };
}
