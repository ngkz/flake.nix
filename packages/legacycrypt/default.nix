{
  lib,
  buildPythonPackage,
  fetchPypi,
  flit,
  libxcrypt,
}:

buildPythonPackage rec {
  pname = "legacycrypt";
  version = "0.3";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-525/0lZmpFFCiyDVr7vs82VFZbLhFRG1Mia+lVxNIpI=";
  };

  format = "pyproject";

  build-system = [ flit ];
  propagatedBuildInputs = [ libxcrypt ];

  # fix for "libcrypt / libxcrypt missing"
  postPatch =
    let
      libcrypt = "${lib.getLib libxcrypt}/lib/libcrypt.so.2";
    in
    ''
      substituteInPlace legacycrypt.py --replace-fail "_find_library('xcrypt')" "\"${libcrypt}\""
    '';

  meta = with lib; {
    description = "Wrapper to the POSIX crypt library call and associated functionality";
    homepage = "https://github.com/tiran/legacycrypt";
    license = licenses.psfl;
  };
}
