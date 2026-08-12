# Python library for controlling the legacy Saleae Logic socket API.
{
  lib,
  buildPythonPackage,
  fetchPypi,
  psutil,
  setuptools,
}:

buildPythonPackage rec {
  pname = "saleae";
  version = "0.12.0";
  format = "setuptools";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-w+pLY316SI0o4YWFfxv9sYNc5Os8ZNgmgsLS69vwXBk=";
  };

  nativeBuildInputs = [ setuptools ];
  propagatedBuildInputs = [ psutil ];

  # python-future is disabled for Python 3.13. On Python 3, the imported
  # names are all builtins, so remove the compatibility import instead.
  postPatch = ''
    substituteInPlace saleae/saleae.py \
      --replace-fail \
        "from __future__ import (absolute_import, division, print_function, unicode_literals)" \
        ""
  '';

  pythonRemoveDeps = [ "future" ];
  pythonImportsCheck = [ "saleae" ];
  doCheck = false;

  meta = with lib; {
    description = "Python library to control a Saleae Logic Analyzer";
    homepage = "https://github.com/ppannuto/python-saleae";
    license = licenses.mit;
    platforms = platforms.all;
  };
}
