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
  version = "4.0.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "angr";
    repo = "pypcode";
    tag = "v${finalAttrs.version}";
    hash = "sha256-qQgOtz8TRbP6LkGehSJM8ig6TsmwTz7gy8aA4dozwoc=";
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
