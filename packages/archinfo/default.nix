# archinfo - Classes with architecture-specific information
{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
}:

buildPythonPackage rec {
  pname = "archinfo";
  version = "9.3.2";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "angr";
    repo = "archinfo";
    tag = "v${version}";
    hash = "sha256-TykkD48/OeeL3VckXw3AWr1I2FCHuL6qa4p15UWX/sU=";
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
