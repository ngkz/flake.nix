# urllib3 1.25.10 - vendored from nixos-20.09 (python2-compatible)
# vendored without the optional TLS/SNI deps (cryptography, pyopenssl, ...),
# which no longer build for python2; requests only needs plain HTTPS via system
# CA bundle.
{
  lib,
  buildPythonPackage,
  fetchPypi,
}:

buildPythonPackage rec {
  pname = "urllib3";
  version = "1.25.10";

  src = fetchPypi {
    inherit pname version;
    sha256 = "91056c15fa70756691db97756772bb1eb9678fa585d9184f24534b100dc60f4a";
  };

  doCheck = false;

  meta = {
    description = "Powerful, sanity-friendly HTTP client for Python";
    homepage = "https://github.com/shazow/urllib3";
    license = lib.licenses.mit;
  };
}
