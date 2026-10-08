# angr-data - Data files for angr
{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
}:

buildPythonPackage rec {
  pname = "angr-data";
  version = "0.1.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "angr";
    repo = "angr-data";
    tag = "v${version}";
    hash = "sha256-DVXVBCWcpB4rEvtOl7Y94CbGu2S/jaIVmxiGDMJuxf4=";
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
