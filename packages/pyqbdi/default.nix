# pyqbdi - Python bindings for QBDI (Quick Binary Dynamic Instrumentation)
{
  lib,
  buildPythonPackage,
  stdenv,
  fetchFromGitHub,
  fetchurl,
  cmake,
  ninja,
  setuptools,
  packaging,
}:

let
  pname = "pyqbdi";
  version = "0.12.1";

  spdlog-archive = fetchurl {
    url = "https://github.com/gabime/spdlog/archive/refs/tags/v1.15.0.zip";
    hash = "sha256-B287TUUrlUMwg7zGbQf3mt26LT/LK5F3q+tzZ9R677s=";
  };

  llvm-src-archive = fetchurl {
    url = "https://github.com/llvm/llvm-project/releases/download/llvmorg-19.1.5/llvm-19.1.5.src.tar.xz";
    hash = "sha256-fXFjWUjk2hgUzo4V7EU5nkCUpUQuhtNSyW3tDysxcbY=";
  };

  llvm-cmake-archive = fetchurl {
    url = "https://github.com/llvm/llvm-project/releases/download/llvmorg-19.1.5/cmake-19.1.5.src.tar.xz";
    hash = "sha256-oIrkd1cf1ekpwn09DSjGFo1Y3QC2NUwt4yZq4Nhq1E8=";
  };

  pybind11-archive = fetchurl {
    url = "https://github.com/pybind/pybind11/archive/v3.0.1.zip";
    hash = "sha256-IPtCD+Fj0GV6JiqN7LYZt8MQHqkds18acifmfEJtTH4=";
  };

  srcWithDeps = stdenv.mkDerivation {
    inherit pname version;
    src = fetchFromGitHub {
      owner = "QBDI";
      repo = "QBDI";
      rev = "v${version}";
      hash = "sha256-wXOvP9ItVQmBuoKWf7ABts1MQBZOTkn8VQOcHk3zpR8=";
    };

    dontConfigure = true;
    dontBuild = true;

    # Create third-party directory structure for CMake to find archives
    installPhase = ''
      mkdir -p "$out"
      cp -a . "$out/"

      mkdir -p "$out/third-party/llvm-download"
      mkdir -p "$out/third-party/llvm-cmake-download"
      mkdir -p "$out/third-party/spdlog_download"
      mkdir -p "$out/third-party/pybind11_download"

      ln -sf ${llvm-src-archive} "$out/third-party/llvm-download/llvm-19.1.5.src.tar.xz"
      ln -sf ${llvm-cmake-archive} "$out/third-party/llvm-cmake-download/cmake-19.1.5.src.tar.xz"
      ln -sf ${spdlog-archive} "$out/third-party/spdlog_download/v1.15.0.zip"
      ln -sf ${pybind11-archive} "$out/third-party/pybind11_download/v3.0.1.zip"
    '';
  };

in
buildPythonPackage {
  inherit pname version;
  format = "setuptools";

  src = srcWithDeps;

  nativeBuildInputs = [
    cmake
    ninja
    setuptools
    packaging
  ];

  # Disable automatic cmake configure - setup.py handles CMake in build_ext
  dontUseCmakeConfigure = true;

  meta = with lib; {
    description = "Python bindings for QBDI - Quick Binary Dynamic Instrumentation framework";
    homepage = "https://github.com/QBDI/QBDI";
    license = licenses.asl20;
    platforms = platforms.linux;
  };
}
