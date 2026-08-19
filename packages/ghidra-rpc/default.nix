# ghidra-rpc - CLI-driven daemon exposing Ghidra over a Unix domain socket
{
  lib,
  buildPythonApplication,
  fetchFromGitHub,
  hatchling,
  pyghidra,
  click,
  jpype1,
}:

buildPythonApplication rec {
  pname = "ghidra-rpc";
  version = "0.2.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "cellebrite-labs";
    repo = "ghidra-rpc";
    tag = "v${version}";
    hash = "sha256-I8aWLxoeJsI0MfWhB7/JJTBPvTA/PW4pgJUhFMZK8ds=";
  };

  build-system = [ hatchling ];

  dependencies = [
    click
    jpype1
    pyghidra
  ];

  pythonImportsCheck = [ "ghidra_rpc" ];

  # Install the upstream Pi skill alongside the CLI package.
  postInstall = ''
    install -Dm644 SKILL.md "$out/share/${pname}/SKILL.md"
  '';

  meta = {
    description = "CLI-driven daemon exposing Ghidra reverse engineering capabilities over a Unix domain socket";
    homepage = "https://github.com/cellebrite-labs/ghidra-rpc";
    license = lib.licenses.mit;
    mainProgram = "ghidra-rpc";
    platforms = lib.platforms.unix;
  };
}
