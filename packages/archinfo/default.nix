# archinfo - Classes with architecture-specific information
{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
}:

buildPythonPackage rec {
  pname = "archinfo";
  version = "9.3.3";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "angr";
    repo = "archinfo";
    tag = "v${version}";
    hash = "sha256-iiclggVwhllM7WNm35/u8zehECXePPXcp0AdmPlyWLo=";
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
