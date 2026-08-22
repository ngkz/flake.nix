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
    rev = "e445924fc6f0c8134c9dd00c9b710f939a235d37";
    hash = "sha256-L965sTpgRv9w3Tozu6AYmwfohwa2a0uegbpZrXj93Uo=";
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
