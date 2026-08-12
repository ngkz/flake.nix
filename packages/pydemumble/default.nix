# pydemumble - Python wrapper for demumble (C++/Rust/Swift symbol demangler)
#
# Built from the upstream GitHub source repo (angr/pydemumble) at the
# v<version> tag, fetched with submodules: nanobind (and its nested
# robin_map) are git submodules that scikit-build-core/cmake compile from
# source. Used by angr 9.3.2.
{
  lib,
  stdenv,
  buildPythonPackage,
  fetchFromGitHub,
  cmake,
  ninja,
  scikit-build-core,
  nanobind,
}:

buildPythonPackage rec {
  pname = "pydemumble";
  version = "0.1.3";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "angr";
    repo = "pydemumble";
    tag = "v${version}";
    fetchSubmodules = true;
    hash = "sha256-Po19NXY4I97Aj1SY1KqpspEqYpVGIsAirOo6iAjBrbk=";
  };

  build-system = [ scikit-build-core ];

  nativeBuildInputs = [
    cmake
    ninja
    nanobind
  ];

  # scikit-build-core drives cmake itself
  dontUseCmakeConfigure = true;

  doCheck = false;

  pythonImportsCheck = [ "pydemumble" ];

  meta = {
    description = "Python wrapper for demumble, a C++/Rust/Swift symbol demangler";
    homepage = "https://github.com/angr/pydemumble";
    license = lib.licenses.bsd2;
    platforms = lib.platforms.unix;
  };
}
