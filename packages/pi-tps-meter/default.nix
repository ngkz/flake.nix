{
  stdenv,
  fetchFromGitHub,
  lib,
  ...
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "pi-tps-meter";
  version = "3.0.4";

  src = fetchFromGitHub {
    owner = "vskrch";
    repo = "pi-tps-meter";
    rev = "cbf35bd0831410b24c1de79e3e2deea9e29b576f";
    hash = "sha256-tD5GqRf9u8oG4dqCIjPk9F4NHSw+QfaTwiwG5ZMcy7A=";
  };

  installPhase = ''
    mkdir -p $out/lib/node_modules/${finalAttrs.pname}
    cp -r * $out/lib/node_modules/${finalAttrs.pname}/
  '';

  meta = {
    description = "Tokens per second meter for pi CLI";
    homepage = "https://github.com/vskrch/pi-tps-meter";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
})
