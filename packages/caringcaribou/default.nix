# caringcaribou - Automotive security exploration tool for CAN buses
{
  lib,
  buildPythonApplication,
  fetchFromGitHub,
  python-can,
  setuptools,
  wheel,
}:

buildPythonApplication rec {
  pname = "caringcaribou";
  version = "0.7-unstable-2026-06-12";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "CaringCaribou";
    repo = "caringcaribou";
    rev = "092eff3c2c95bb7952a2a92ac12b6c1c29035b70";
    hash = "sha256-/em25rCDldixZq3LtDah981VjPGLfy+7MdzU/M/zvik=";
  };

  build-system = [
    setuptools
    wheel
  ];

  dependencies = [ python-can ];

  pythonImportsCheck = [ "caringcaribou.caringcaribou" ];

  meta = {
    description = "A friendly automotive security exploration tool for the CAN bus";
    homepage = "https://github.com/CaringCaribou/caringcaribou";
    license = lib.licenses.gpl3Only;
    mainProgram = "caringcaribou";
    platforms = lib.platforms.linux;
  };
}
