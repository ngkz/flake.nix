# angr-data - Data files for angr
{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
}:

buildPythonPackage rec {
  pname = "angr-data";
  version = "0.1.0.post1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "angr";
    repo = "angr-data";
    tag = "v${version}";
    hash = "sha256-9w9zKUw0xgljIBVNJZWniXstHHyv+r9xaoFLiZx04TE=";
  };

  build-system = [ setuptools ];

  doCheck = false;

  pythonImportsCheck = [ "angr_data" ];

  meta = {
    description = "Data files for angr";
    homepage = "https://github.com/angr/angr-data";
    license = lib.licenses.bsd2;
    platforms = lib.platforms.unix;
  };
}
