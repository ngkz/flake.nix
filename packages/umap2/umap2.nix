# umap2 - USB Host Security Assessment Tool (python2)
{
  lib,
  buildPythonApplication,
  fetchFromGitHub,
  setuptools,
  docopt,
  kittyfuzzer,
  pyserial,
  six,
}:

buildPythonApplication rec {
  pname = "umap2";
  version = "2.0.1-unstable-2021-07-13";

  src = fetchFromGitHub {
    owner = "nccgroup";
    repo = "umap2";
    rev = "a428667306f6bbc51ca02370aaf84d58f1283756";
    hash = "sha256-iZtS1jEV0UgK3rjSOBr4phVo7q932CGqt1EvgeGCaOE=";
  };

  pyproject = true;

  build-system = [
    setuptools
  ];

  propagatedBuildInputs = [
    docopt
    kittyfuzzer
    pyserial
    six
  ];

  pythonImportsCheck = [ "umap2" ];

  meta = {
    description = "USB Host Security Assessment Tool - Revision 2";
    homepage = "https://github.com/nccgroup/umap2";
    license = lib.licenses.gpl3Only;
    mainProgram = "umap2emulate";
    platforms = lib.platforms.linux;
  };
}
