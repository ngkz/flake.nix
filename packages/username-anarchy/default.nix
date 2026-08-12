{
  lib,
  stdenv,
  fetchFromGitHub,
  ruby,
  makeWrapper,
}:

stdenv.mkDerivation {
  pname = "username-anarchy";
  version = "0.6";

  src = fetchFromGitHub {
    owner = "urbanadventurer";
    repo = "username-anarchy";
    rev = "v0.6";
    hash = "sha256-46hl1ynA/nc2R70VHhOqbux6B2hwiJWs/sf0ZRwNFf0=";
  };

  nativeBuildInputs = [
    makeWrapper
  ];

  installPhase = ''
    mkdir -p $out/bin $out/lib/''${pname}
    install -m 444 username-anarchy format-plugins.rb $out/lib/''${pname}
    cp -r names $out/lib/''${pname}
    makeWrapper ${ruby}/bin/ruby $out/bin/''${pname} \
      --add-flags "$out/lib/''${pname}/username-anarchy"
  '';

  meta = {
    description = "Username tools for penetration testing";
    homepage = "https://www.morningstarsecurity.com/research/username-anarchy";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
    maintainers = with lib.maintainers; [ ngkz ];
  };
}
