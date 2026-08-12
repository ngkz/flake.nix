# six 1.15.0 - vendored from nixos-20.09 (python2-compatible)
{
  lib,
  buildPythonPackage,
  fetchPypi,
}:

buildPythonPackage rec {
  pname = "six";
  version = "1.15.0";

  src = fetchPypi {
    inherit pname version;
    sha256 = "30639c035cdb23534cd4aa2dd52c3bf48f06e5f4a941509c8bafd8ce11080259";
  };

  # prevent infinite recursion with pytest
  doCheck = false;

  meta = {
    description = "A Python 2 and 3 compatibility library";
    homepage = "https://pypi.python.org/pypi/six/";
    license = lib.licenses.mit;
  };
}
