# pyxdia - Extract useful program information from PDB files
#
# The Python package itself is pure Python (fetched as the PyPI sdist via
# fetchPypi, which uses the stable mirror://pypi URL). At build time its
# setup.py would download pre-built native components from the xdia GitHub
# release (xdia.exe + msdia140.dll, and the xdialdr loader) into pyxdia/bin/.
# We instead fetch those release assets with fetchurl and pre-place them in
# pyxdia/bin/ during postPatch, so setup.py's check_xdia_install finds them
# already installed and the sandboxed build never touches the network. build_py
# then ships them as package_data {"pyxdia": ["bin/*"]}.
#
# x86_64-linux only: upstream only ships an x86_64 xdialdr loader and runs the
# x86_64 xdia.exe under it; other arches would also need the blink emulator.
{
  lib,
  buildPythonPackage,
  fetchPypi,
  fetchurl,
  setuptools,
  wheel,
  unzip,
}:

let
  xdiaRelease = version: "https://github.com/mborgerson/xdia/releases/download/v${version}";
in
buildPythonPackage rec {
  pname = "pyxdia";
  version = "0.1.1";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-AyQlPu/KRlWj8rC4VayE+COKJT2XWzPkAbzXsjsED1o=";
  };

  # Pre-built native components shipped from the xdia GitHub release. setup.py
  # expects exactly these filenames in pyxdia/bin/.
  xdiaZip = fetchurl {
    url = "${xdiaRelease version}/xdia.zip";
    hash = "sha256-SDd4JR4NKw6imD0IARynX0tLPN1dao0Ompea6dJSoGo=";
  };
  xdialdrTar = fetchurl {
    url = "${xdiaRelease version}/xdialdr.tar.xz";
    hash = "sha256-s2595p3bbASfKNwlvDkHg8w3ZCm9j2c9HztPD1sOtuE=";
  };

  # setup.py imports wheel.bdist_wheel; pyproject.toml has no [build-system]
  # so default to setuptools + wheel.
  build-system = [
    setuptools
    wheel
  ];

  nativeBuildInputs = [ unzip ];

  postPatch = ''
    mkdir -p pyxdia/bin
    # xdia.zip extracts flat: xdia.exe, msdia140.dll, xdia.LICENSE.txt
    unzip -o "$xdiaZip" -d pyxdia/bin >/dev/null
    # xdialdr.tar.xz extracts flat: xdialdr, xdialdr.LICENSE.txt
    tar -xf "$xdialdrTar" -C pyxdia/bin
    chmod +x pyxdia/bin/xdialdr
  '';

  doCheck = false;

  pythonImportsCheck = [ "pyxdia" ];

  meta = {
    description = "Extract useful program information from PDB files";
    homepage = "https://github.com/mborgerson/xdia";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
  };
}
