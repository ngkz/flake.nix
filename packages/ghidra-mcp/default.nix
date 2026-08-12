{
  lib,
  ghidra,
  gradle,
  fetchFromGitHub,
}:

ghidra.buildGhidraExtension (finalAttrs: {
  pname = "ghidra-mcp";
  version = "6.0.0";

  src = fetchFromGitHub {
    owner = "bethington";
    repo = "ghidra-mcp";
    tag = "v${finalAttrs.version}";
    hash = "sha256-LnhhJwycO8NQV+YaTP7ZoxGkoGLkc14BwY66wczbpp0=";
  };

  gradleBuildTask = "buildExtension";

  # ghidra-mcp uses its own buildExtension task (not Ghidra's
  # buildExtension.gradle), which writes the ZIP to build/distributions/
  # instead of dist/. Move it into dist/ so the default installPhase finds it.
  postBuild = ''
    mkdir -p dist
    cp build/distributions/GhidraMCP-${finalAttrs.version}.zip dist/
  '';

  meta = with lib; {
    description = "GhidraMCP — Ghidra plugin with 200+ MCP tools for AI-powered reverse engineering";
    homepage = "https://github.com/bethington/ghidra-mcp";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
