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
    rev = "950d0cf35e4f917b6836565d76e38bcf7fcf2d5f";
    hash = "sha256-LobjcmiJR9ePZP0w1G93bdVFt4r36hyPK2ideKDr6VQ=";
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
