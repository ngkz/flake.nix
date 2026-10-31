{
  lib,
  python,
  buildPythonApplication,
  fetchFromGitHub,
  fetchpatch,
  makePythonPath,
  fastmcp,
  httpx,
  requests,
}:

let
  # Temporary fix for the nixos-26.05 check phase failure, ported from
  # https://github.com/NixOS/nixpkgs/pull/580411. anyio >= 4.14 aborts the
  # stateful proxy client session teardown, so the three proxy tests of
  # fastmcp 3.2.3 fail. Drop once nixos-26.05 carries the fix.
  fastmcp-fixed = fastmcp.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      (fetchpatch {
        url = "https://github.com/PrefectHQ/fastmcp/commit/ddcdf648131b51d605f133d13e5c942ea008ab28.patch";
        stripLen = 2;
        extraPrefix = "src/";
        hash = "sha256-A4dPqgneJRZ/TBbiZOzJTpmMFMQbS6HOaxgmtXkPJe0=";
      })
    ];
    postPatch = ''
      ${old.postPatch or ""}
      # The patch's `anyio.CancelScope` needs a name 3.2.3 does not import.
      substituteInPlace src/fastmcp/server/providers/proxy.py \
        --replace-fail 'import base64' "import anyio${"\n"}import base64"
    '';
  });
in

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
    fastmcp-fixed
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
