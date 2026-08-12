{
  lib,
  maven,
  fetchFromGitHub,
  jadx,
}:

maven.buildMavenPackage rec {
  pname = "jadx-ai-mcp";
  version = "6.4.1";

  src = fetchFromGitHub {
    owner = "zinja-coder";
    repo = "jadx-ai-mcp";
    rev = "V${version}";
    hash = "sha256-qsVKeveADEeFEAmXz7UwgixzqRmAsYvd9geOLNyEWvs=";
  };

  # Fix upstream pom.xml: use local JAR with system scope instead of remote jadx-all
  postPatch = ''
    substituteInPlace pom.xml \
      --replace-fail '<version>1.5.5</version>' \
        '<version>LOCAL</version><scope>system</scope><systemPath>${jadx}/lib/jadx-1.5.6-all.jar</systemPath>'
  '';

  mvnHash = "sha256-xYGv09YkfgkKBDc9KjYdrF6LRCOOWOzkXyc1FnNx+5g=";

  installPhase = ''
    runHook preInstall

    install -Dm644 target/jadx-ai-mcp-${version}.jar \
      $out/share/java/${pname}-${version}.jar

    runHook postInstall
  '';

  meta = with lib; {
    description = "JADX plugin to integrate MCP server for LLM-based Android APK analysis";
    homepage = "https://github.com/zinja-coder/jadx-ai-mcp";
    license = licenses.asl20;
    maintainers = with maintainers; [ ];
  };
}
