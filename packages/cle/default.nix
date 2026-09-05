# cle - CLE Loads Everything, a binary loader for angr
{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  archinfo,
  arpy,
  cart,
  cffi,
  minidump,
  pefile,
  pyelftools,
  pyvex,
  pyxbe,
  pyxdia,
  sortedcontainers,
  uefi-firmware,
}:

buildPythonPackage rec {
  pname = "cle";
  version = "9.3.4";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "angr";
    repo = "cle";
    tag = "v${version}";
    hash = "sha256-903Pw/G3IIdpPpj5UUITjJ4WPWMEOL4yaEXlvgzB1+o=";
  };

  # upstream pins arpy==1.1.1; nixpkgs ships a newer 2.x which works
  pythonRelaxDeps = [ "arpy" ];

  build-system = [ setuptools ];

  dependencies = [
    archinfo
    arpy
    cart
    minidump
    pefile
    pyelftools
    pyvex
    pyxbe
    pyxdia
    sortedcontainers
    uefi-firmware
    # cffi is used at runtime to compile SimProcedures
    cffi
  ];

  doCheck = false;

  pythonImportsCheck = [ "cle" ];

  meta = {
    description = "Binary loader for angr (CLE Loads Everything)";
    homepage = "https://github.com/angr/cle";
    license = lib.licenses.bsd2;
    platforms = lib.platforms.unix;
  };
}
