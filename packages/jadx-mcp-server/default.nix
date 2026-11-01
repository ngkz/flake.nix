{
  lib,
  python,
  buildPythonApplication,
  fetchFromGitHub,
  makePythonPath,
  fastmcp,
  httpx,
  requests,
}:

buildPythonApplication rec {
  pname = "jadx-mcp-server";
  version = "6.5.0";

  src = fetchFromGitHub {
    owner = "zinja-coder";
    repo = "jadx-mcp-server";
    rev = "a8e5b7de4f7d7f9ef0ccea9d063631133105bd34";
    hash = "sha256-5x9PbQRgWseV1TRgtjYZfMsByP3UgIY8eCRb8gRZdhI=";
  };
  pyproject = false;

  propagatedBuildInputs = [
    fastmcp
    httpx
    requests
  ];

  installPhase = ''
    runHook preInstall

    sitepkgs=$out/${python.sitePackages}

    mkdir -p $out/bin $sitepkgs

    cp -r src $sitepkgs/
    install -m755 jadx_mcp_server.py $sitepkgs/jadx_mcp_server.py

    makeWrapper ${python.interpreter} $out/bin/jadx-mcp-server \
      --add-flags "$sitepkgs/jadx_mcp_server.py" \
      --set PYTHONPATH "$sitepkgs:${makePythonPath propagatedBuildInputs}"

    runHook postInstall
  '';

  meta = with lib; {
    description = "JADX MCP Server";
    homepage = "https://github.com/zinja-coder/jadx-mcp-server";
    license = licenses.asl20;
    mainProgram = pname;
  };
}
