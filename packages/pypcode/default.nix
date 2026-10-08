# pypcode - Decompiler IR library
{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  cmake,
  nanobind,
  setuptools,
}:

buildPythonPackage (finalAttrs: {
  pname = "pypcode";
  version = "4.0.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "angr";
    repo = "pypcode";
    tag = "v${finalAttrs.version}";
    hash = "sha256-OwnwgN2/MElH7SOwauS/hfVkgwAd0uMH0y00Ydkq+8I=";
  };

  build-system = [
    cmake
    setuptools
    nanobind
  ];

  dontUseCmakeConfigure = true;

  doCheck = false;

  pythonImportsCheck = [ "pypcode" ];

  meta = {
    description = "Decompiler intermediate representation library";
    homepage = "https://github.com/angr/pypcode";
    license = lib.licenses.bsd2;
    platforms = lib.platforms.unix;
  };
})
