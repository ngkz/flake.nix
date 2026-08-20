# claripy - Abstraction layer for constraint solvers
{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  cachetools,
  z3-solver,
}:

buildPythonPackage rec {
  pname = "claripy";
  version = "9.3.3";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "angr";
    repo = "claripy";
    tag = "v${version}";
    hash = "sha256-XhLqM9PkysJ+gS21ZDLLumaK2TgC/4k8e0BulPWWoVA=";
  };

  # upstream pins z3-solver==4.13.0.0; nixpkgs ships a newer 4.x which works
  pythonRelaxDeps = [ "z3-solver" ];

  build-system = [ setuptools ];

  dependencies = [
    cachetools
    z3-solver
  ];

  # nixpkgs' z3-solver ships no dist-info, so the runtime deps check can't
  # detect it; z3-solver is still propagated via `dependencies` above.
  dontCheckRuntimeDeps = true;

  doCheck = false;

  pythonImportsCheck = [ "claripy" ];

  meta = {
    description = "Abstraction layer for constraint solvers";
    homepage = "https://github.com/angr/claripy";
    license = lib.licenses.bsd2;
    platforms = lib.platforms.unix;
  };
}
