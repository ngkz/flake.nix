{
  stdenv,
  fetchFromGitHub,
  lib,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "pi-prefill";
  version = "0.1.2";

  src = fetchFromGitHub {
    owner = "eliaskg";
    repo = "pi-prefill";
    rev = "d836287aa30891e0023c128da889badd16221583";
    hash = "sha256-Wowtx5rct5u2eQpixk2A7kL5dr7vMqlG/TRb0yiCbOU=";
  };

  # TypeScript pi extension: pi loads extensions/prefill.ts through jiti,
  # so there is nothing to compile and no runtime dependency to install.
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    mkdir -p $out/lib/node_modules/${finalAttrs.pname}
    cp -r * $out/lib/node_modules/${finalAttrs.pname}/
  '';

  meta = {
    description = "Live prefill progress bar for pi";
    homepage = "https://github.com/eliaskg/pi-prefill";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
})
