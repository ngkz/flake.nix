{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:
buildNpmPackage (finalAttrs: {
  pname = "pi-openrouter-realtime";
  version = "0.3.7";

  src = fetchFromGitHub {
    owner = "olixis";
    repo = "pi-openrouter-plus";
    rev = "eb29f6864f63152d19d39dae86d8a59afa583a54";
    hash = "sha256-Z7WGmOllKAIArtxiuP0lvNWtWXm+3y21257ud1sBqG8=";
  };

  npmDepsHash = "sha256-pl/SbKlqsnjvjbdl4eHoe5cEYcXhEVPWIZY+iRI3oPk=";

  # TypeScript pi source; dependencies are installed by npm below but there is
  # no build script to run.
  dontNpmBuild = true;

  meta = {
    description = "OpenRouter extension for pi — real-time model sync";
    homepage = "https://github.com/olixis/pi-openrouter-plus";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
})
