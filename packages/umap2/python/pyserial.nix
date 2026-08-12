# pyserial 3.4 - vendored from nixos-20.09 (python2-compatible)
{
  lib,
  buildPythonPackage,
  fetchPypi,
}:

buildPythonPackage rec {
  pname = "pyserial";
  version = "3.4";

  src = fetchPypi {
    inherit pname version;
    sha256 = "09y68bczw324a4jb9a1cfwrbjhq179vnfkkkrybbksp0vqgl0bbf";
  };

  meta = {
    homepage = "https://github.com/pyserial/pyserial";
    license = lib.licenses.psfl;
    description = "Python serial port extension";
  };
}
