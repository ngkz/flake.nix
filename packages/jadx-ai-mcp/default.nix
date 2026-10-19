{
  lib,
  maven,
  fetchFromGitHub,
  jadx,
}:

maven.buildMavenPackage rec {
  pname = "jadx-ai-mcp";
  version = "6.5.0";

  src = fetchFromGitHub {
    owner = "zinja-coder";
    repo = "jadx-ai-mcp";
    rev = "v${version}";
    hash = "sha256-iHUUA2KSZ9+OkYCCLtWLruDLx6N7nIR/3Esz9dWlt9U=";
  };

  # Fix upstream pom.xml: use local JAR with system scope instead of remote jadx-all
  postPatch = ''
    substituteInPlace pom.xml \
      --replace-fail '<version>1.5.5</version>' \
        '<version>LOCAL</version><scope>system</scope><systemPath>${jadx}/lib/jadx-1.5.6-all.jar</systemPath>'
  '';

  mvnHash = "sha256-YFrPtjJ1Dcg1L+mvLmJe6u9M9S3UsYen6N834rzKxvk=";

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
