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
    rev = "6bb030470d3f606f6b83b5eb3d2acc22f608267a";
    hash = "sha256-0RACu520e6ooOtzhTu2oND3ezRz0meTniyTZk4lsBKw=";
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
