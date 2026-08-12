# bitstring 3.1.5 - vendored from nixos-20.09 (python2-compatible)
{
  lib,
  buildPythonPackage,
  fetchPypi,
  bitarray,
}:

buildPythonPackage rec {
  pname = "bitstring";
  version = "3.1.5";

  src = fetchPypi {
    inherit pname version;
    sha256 = "1algq30j6rz12b1902bpw7iijx5lhrfqhl80d4ac6xzkrrpshqy1";
    extension = "zip";
  };

  propagatedBuildInputs = [ bitarray ];

  meta = {
    description = "Module for binary data manipulation";
    homepage = "https://github.com/scott-griffiths/bitstring";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
}
