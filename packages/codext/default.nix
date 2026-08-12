{
  lib,
  buildPythonPackage,
  fetchPypi,
  legacycrypt,
  markdown2,
  setuptools-scm,
}:

buildPythonPackage rec {
  pname = "codext";
  version = "1.16.5";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-sNfZ4Mo2wEW2SbWLTcYDTv67R/3gIwGcMqLFlqLSy8o=";
  };

  format = "pyproject";
  build-system = [ setuptools-scm ];

  propagatedBuildInputs = [
    legacycrypt
    markdown2
  ];

  meta = with lib; {
    description = "Native codecs extension";
    homepage = "https://pypi.org/project/codext/";
    license = licenses.gpl3Plus;
  };
}
