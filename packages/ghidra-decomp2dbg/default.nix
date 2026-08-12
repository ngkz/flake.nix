{
  lib,
  ghidra,
  fetchFromGitHub,
}:

ghidra.buildGhidraExtension rec {
  pname = "ghidra-decomp2dbg";
  version = "3.14.0";

  src = fetchFromGitHub {
    owner = "mahaloz";
    repo = "decomp2dbg";
    rev = "v${version}";
    hash = "sha256-xayYF1iAbTi1V0P7+WQ+W0nCJutcnK026z2wNwifKxw=";

  };

  sourceRoot = "${src.name}/decompilers/d2d_ghidra";
  gradleBuildTask = "buildExtension";

  meta = {
    description = "Ghidra plugin for decomp2dbg";
    homepage = "https://github.com/mahaloz/decomp2dbg";
    license = lib.licenses.bsd2;
    platforms = lib.platforms.all;
  };
}
