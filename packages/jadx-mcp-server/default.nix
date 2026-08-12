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
  version = "6.4.1";

  src = fetchFromGitHub {
    owner = "zinja-coder";
    repo = "jadx-mcp-server";
    rev = "2370868045147c6646ded1067160d12e153db148";
    hash = "sha256-zmV7P8c2pCxZegMH2gMsb4BIOD2m1PMiEoA0LkGOnEc=";
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
