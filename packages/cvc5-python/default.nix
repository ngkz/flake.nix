# cvc5 Python bindings
{
  lib,
  stdenv,
  buildPythonPackage,
  fetchFromGitHub,
  python,
  cmake,
  flex,
  pkg-config,
  patchelf,
  cvc5,
  cadical,
  symfpu,
  gmp,
  gtest,
  boost,
  jdk,
  libpoly,
}:

let
  pythonEnv = python.withPackages (
    ps: with ps; [
      cython
      pip
      pyparsing
      setuptools
      tomli
    ]
  );

  # XXX update needed when cvc5 upgrade
  cadical' = cadical.overrideAttrs (_: {
    version = "2.1.3";
    src = fetchFromGitHub {
      owner = "arminbiere";
      repo = "cadical";
      rev = "rel-2.1.3";
      hash = "sha256-W3kO+6nVzkmJXyHJU+NZWP0oatK3gon4EWF1/03rgL4=";
    };
  });

  # XXX update needed when cvc5 upgrade
  pythonicApi = fetchFromGitHub {
    owner = "cvc5";
    repo = "cvc5_pythonic_api";
    rev = "cdcac7cb2da79d922fc44628c1c3c5f60c2eeec4";
    hash = "sha256-uvDziNaNgM/NB1OHjqBILKiXtBMchk3i10xV+JG2mek=";
  };
in
buildPythonPackage (finalAttrs: {
  pname = "cvc5-python";
  format = "other";

  inherit (cvc5) version src;

  nativeBuildInputs = [
    cmake
    flex
    patchelf
    pkg-config
    pythonEnv
  ];

  buildInputs = [
    cadical'.dev
    symfpu
    gmp
    gtest
    boost
    jdk
    libpoly
  ];

  propagatedBuildInputs = [ cvc5 ];

  postPatch = ''
    # The upstream install component uses repairwheel to make a self-contained
    # wheel. Nix provides cvc5 as a runtime dependency, so only build the
    # extension and install it through the normal Python package hooks.
    substituteInPlace src/api/python/CMakeLists.txt \
      --replace-fail \
        "find_package(Repairwheel 0.3.2 REQUIRED)" \
        "# repairwheel is not needed for the Nix package"
  '';

  preConfigure = ''
    patchShebangs ./src/
  '';

  dontUseCmakeConfigure = true;
  dontUsePythonBuild = true;

  cmakeFlags = [
    "-DCMAKE_BUILD_TYPE=Production"
    "-DBUILD_SHARED_LIBS=ON"
    "-DBUILD_BINDINGS_PYTHON=ON"
    "-DENABLE_AUTO_DOWNLOAD=OFF"
    "-DUSE_PYTHON_VENV=OFF"
    "-DUSE_POLY=ON"
    "-DPYTHONIC_PATH=${pythonicApi}"
    "-DPython_EXECUTABLE=${pythonEnv.interpreter}"
    "-DPython_BASE_EXECUTABLE=${pythonEnv.interpreter}"
  ];

  configurePhase = ''
    runHook preConfigure

    cmake -S . -B build \
      -DCMAKE_INSTALL_PREFIX="$out" \
      ${lib.escapeShellArgs finalAttrs.cmakeFlags}

    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild
    cmake --build build --target cvc5_python_api --parallel "$NIX_BUILD_CORES"
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    ${pythonEnv.interpreter} -m pip install \
      --no-index \
      --no-build-isolation \
      --no-deps \
      --prefix "$out" \
      build/src/api/python

    runHook postInstall
  '';

  postInstall = ''
    for extension in "$out/${python.sitePackages}"/cvc5/*.so; do
      patchelf --set-rpath "${
        lib.makeLibraryPath [
          cvc5
          stdenv.cc.cc.lib
        ]
      }" "$extension"
    done
  '';

  pythonImportsCheck = [
    "cvc5"
    "cvc5.pythonic"
  ];

  meta = {
    description = "Python bindings for the cvc5 theorem prover";
    homepage = "https://cvc5.github.io/";
    license = lib.licenses.bsd3;
    platforms = lib.platforms.linux;
  };
})
