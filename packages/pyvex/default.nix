# pyvex - Python interface to libVEX and VEX IR
# Upstream switched to scikit-build-core (cmake) and vendors libVEX as a git
# submodule, so we fetch with submodules and let scikit-build-core drive the
# cmake build.
{
  lib,
  stdenv,
  buildPythonPackage,
  buildPackages,
  fetchFromGitHub,
  cmake,
  ninja,
  scikit-build-core,
  bitstring,
  cffi,
}:

buildPythonPackage rec {
  pname = "pyvex";
  version = "9.3.4";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "angr";
    repo = "pyvex";
    tag = "v${version}";
    fetchSubmodules = true;
    hash = "sha256-Qne898CIlnDW3PkMJEQfMqmJgvVVLXIW5VCk+QhecG0=";
  };

  build-system = [ scikit-build-core ];

  # nixpkgs ships scikit-build-core 0.11.x; upstream pins ~=0.12.2 but 0.11
  # builds pyvex fine. Relax the pin so the no-isolation build env is happy.
  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace-fail 'scikit-build-core ~= 0.12.2' 'scikit-build-core'
  '';

  nativeBuildInputs = [
    cmake
    ninja
  ];

  depsBuildBuild = [ buildPackages.stdenv.cc ];

  dependencies = [
    bitstring
    cffi
  ];

  # scikit-build-core drives cmake itself
  dontUseCmakeConfigure = true;

  doCheck = false;

  pythonImportsCheck = [ "pyvex" ];

  meta = {
    description = "Python interface to libVEX and VEX IR";
    homepage = "https://github.com/angr/pyvex";
    license = with lib.licenses; [
      bsd2
      gpl3Plus
    ];
    platforms = lib.platforms.unix;
  };
}
