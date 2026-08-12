{
  stdenv,
  fetchFromGitHub,
  openssh,
  pkg-config,
  glib,
  gcr_4,
}:

stdenv.mkDerivation rec {
  pname = "gnome-ssh-askpass4";

  inherit (openssh) src version;
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    glib
    gcr_4
  ];

  buildPhase = ''
    cd contrib
    make ${pname}
  '';

  dontConfigure = true;

  installPhase = ''
    install -Dm755 ${pname} $out/libexec/${pname}
  '';
}
