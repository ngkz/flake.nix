# chardet 3.0.4 - vendored from nixos-20.09 (python2-compatible)
{
  lib,
  buildPythonPackage,
  fetchPypi,
}:

buildPythonPackage rec {
  pname = "chardet";
  version = "3.0.4";

  src = fetchPypi {
    inherit pname version;
    sha256 = "1bpalpia6r5x1kknbk11p1fzph56fmmnp405ds8icksd3knr5aw4";
  };

  doCheck = false;

  meta = {
    homepage = "https://github.com/chardet/chardet";
    description = "Universal encoding detector";
    license = lib.licenses.lgpl2;
  };
}
