# .NET deobfuscator and unpacker.
{
  buildDotnetModule,
  dotnetCorePackages,
  fetchFromGitHub,
  lib,
}:
buildDotnetModule {
  pname = "de4dot-kant2002";
  version = "3.3.0-unstable-2026-08-20";

  src = fetchFromGitHub {
    owner = "kant2002";
    repo = "de4dot";
    rev = "8803a18111b36675eed09c95322bbdcb1bed45c7";
    hash = "sha256-NI1Mh4Kt5mBxcalM3tq/bsRZNf/i3U0IuAjzqBcsXVM=";
  };

  projectFile = "de4dot/de4dot.csproj";
  nugetDeps = ./deps.json;

  dotnet-sdk = dotnetCorePackages.sdk_10_0;
  dotnet-runtime = dotnetCorePackages.runtime_10_0;

  dotnetRestoreFlags = [ "-p:TargetFramework=net10.0" ];
  dotnetBuildFlags = [
    "-f"
    "net10.0"
  ];
  dotnetInstallFlags = [
    "-f"
    "net10.0"
  ];
  selfContainedBuild = true;
  executables = [ "de4dot" ];

  meta = {
    description = "Open source .NET deobfuscator and unpacker (kant2002 fork)";
    homepage = "https://github.com/kant2002/de4dot";
    license = lib.licenses.gpl3Only;
    mainProgram = "de4dot";
    platforms = lib.platforms.linux;
  };
}
