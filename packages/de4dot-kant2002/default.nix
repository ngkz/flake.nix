# .NET deobfuscator and unpacker.
{
  buildDotnetModule,
  dotnetCorePackages,
  fetchFromGitHub,
  lib,
}:
buildDotnetModule {
  pname = "de4dot-kant2002";
  version = "3.3.0-unstable-2026-08-09";

  src = fetchFromGitHub {
    owner = "kant2002";
    repo = "de4dot";
    rev = "289d6a43e3854a40b35b1dbfcdb58d10fe3987be";
    hash = "sha256-YPJeosr5Eyrd93iI1uhsLlpOevLl7QQ11zGiM+HRpy4=";
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
    description = "Open source .NET deobfuscator and unpacker";
    homepage = "https://github.com/kant2002/de4dot";
    license = lib.licenses.gpl3Only;
    mainProgram = "de4dot";
    platforms = lib.platforms.linux;
  };
}
