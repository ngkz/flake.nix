# angr-data - Data files for angr
{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
}:

buildPythonPackage rec {
  pname = "angr-data";
  version = "0.2.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "angr";
    repo = "angr-data";
    tag = "v${version}";
    hash = "sha256-xnU3XWvYsQGaCFy2GEwkJvsVbZcg7pHqDXUEIftDRNg=";
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
