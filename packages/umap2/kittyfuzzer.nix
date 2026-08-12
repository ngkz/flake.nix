# kittyfuzzer - Kitty fuzzing framework (python2)
{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
  bitstring,
  docopt,
  requests,
  six,
}:

buildPythonPackage rec {
  pname = "kittyfuzzer";
  version = "0.7.4";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-MD4Gm86g58oJ9hqhUi5Ai/zFZAhHJ8z6Z1iYzFjJGoU=";
  };

  propagatedBuildInputs = [
    setuptools
    bitstring
    docopt
    requests
    six
  ];

  pythonImportsCheck = [ "kitty" ];

  meta = {
    description = "Kitty fuzzing framework";
    homepage = "https://pypi.org/project/kittyfuzzer/";
    license = lib.licenses.asl20;
    mainProgram = "kitty-tool";
    platforms = lib.platforms.linux;
  };
}
