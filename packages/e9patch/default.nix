# E9Patch - A powerful static binary rewriting tool for x86_64 Linux ELF binaries
{
  lib,
  stdenv,
  fetchFromGitHub,
  zlib,
  xxd,
  multimarkdown,
}:

let
  pname = "e9patch";
  version = "1.0.1";

  src = fetchFromGitHub {
    owner = "GJDuck";
    repo = "e9patch";
    tag = "v${version}";
    hash = "sha256-SymjILUWGJsuuVEeboOYU80VrcdIDKt+iyp3Jv7nv6A=";
  };

in
stdenv.mkDerivation {
  inherit pname version src;

  outputs = [
    "out"
    "dev"
    "doc"
    "man"
  ];

  buildInputs = [
    zlib.dev
  ];

  nativeBuildInputs = [
    xxd
    multimarkdown
  ];

  buildFlags = [
    "release"
  ];

  makeFlags = [
    "PREFIX=${placeholder "out"}"
  ];

  meta = with lib; {
    description = "A powerful static binary rewriting tool for x86_64 Linux ELF binaries";
    homepage = "https://github.com/GJDuck/e9patch";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
  };
}
