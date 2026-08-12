# requests 2.24.0 - vendored from nixos-20.09 (last python2-compatible line)
{
  lib,
  buildPythonPackage,
  fetchPypi,
  urllib3,
  idna,
  chardet,
  certifi,
}:

buildPythonPackage rec {
  pname = "requests";
  version = "2.24.0";

  src = fetchPypi {
    inherit pname version;
    sha256 = "b3559a131db72c33ee969480840fff4bb6dd111de7dd27c8ee1f820f4f00231b";
  };

  propagatedBuildInputs = [
    urllib3
    idna
    chardet
    certifi
  ];

  # tests require networking
  doCheck = false;

  meta = {
    description = "An Apache2 licensed HTTP library, written in Python, for human beings";
    homepage = "http://docs.python-requests.org/en/latest/";
    license = lib.licenses.asl20;
  };
}
