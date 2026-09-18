# archinfo - Classes with architecture-specific information
{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
}:

buildPythonPackage rec {
  pname = "archinfo";
  version = "10.0.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "angr";
    repo = "archinfo";
    tag = "v${version}";
    hash = "sha256-dWCAHYRtTUOTfuCOmDpmlHSshVraBYUkJrmjaNNymAc=";
  };

  build-system = [ setuptools ];

  doCheck = false;

  pythonImportsCheck = [ "archinfo" ];

  meta = {
    description = "Classes with architecture-specific information useful to other projects";
    homepage = "https://github.com/angr/archinfo";
    license = lib.licenses.bsd2;
    platforms = lib.platforms.unix;
  };
}
