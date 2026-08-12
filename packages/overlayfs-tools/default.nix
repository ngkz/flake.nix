{
  lib,
  stdenv,
  fetchFromGitHub,
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
    rev = "11ed6b4776bb9c68cf76652321e754c19549b58a";
    hash = "sha256-Z7cZjBYeDsXLZzpjjul9jeDT5EAByZBiZt6aTOvK+Bo=";
  };

  doCheck = false;

  nativeBuildInputs = [
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
