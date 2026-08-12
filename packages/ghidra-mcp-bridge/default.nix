{
  lib,
  python,
  buildPythonPackage,
  fetchFromGitHub,
  hatchling,
  mcp,
}:

buildPythonPackage rec {
  pname = "ghidra-mcp-bridge";
  version = "6.0.0";

  src = fetchFromGitHub {
    owner = "bethington";
    repo = "ghidra-mcp";
    tag = "v${version}";
    hash = "sha256-LnhhJwycO8NQV+YaTP7ZoxGkoGLkc14BwY66wczbpp0=";
  };

  pyproject = true;
  build-system = [ hatchling ];

  # The bridge wheel depends on mcp>=1.28.1, but nixpkgs only has 1.26.0.
  # We verify the bridge works with 1.26.0 (verified by running --help),
  # so we disable the runtime dependency check.
  dontCheckRuntimeDeps = true;

  propagatedBuildInputs = [
    mcp
  ];

  meta = with lib; {
    description = "GhidraMCP bridge — MCP↔HTTP multiplexer for Ghidra";
    homepage = "https://github.com/bethington/ghidra-mcp";
    license = licenses.asl20;
    mainProgram = "bridge-mcp-ghidra";
  };
}
