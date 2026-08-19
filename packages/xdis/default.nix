{ lib, buildPythonPackage, click, fetchFromGitHub, pytestCheckHook, setuptools, six }:

buildPythonPackage rec {
  pname = "xdis";
  version = "6.3.0.post1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "rocky";
    repo = "python-xdis";
    rev = "d658a890d51013bb8673a18c64a286c9ec6de3cb";
    hash = "sha256-xXNF2tAWF9d9ktXL2uaCrlIwPSQcp65Zkm4r7FeXE0A=";
  };

  build-system = [ setuptools ];

  patches = [ ./python-3.13.15-support.patch ];

  dependencies = [ click six ];

  nativeCheckInputs = [ pytestCheckHook ];

  pythonImportsCheck = [ "xdis" ];

  disabledTestPaths = [
    # import file mismatch:
    # imported module 'test_disasm' has this __file__ attribute:
    #   /build/source/pytest/test_disasm.py
    # which is not the same as the test file we want to collect:
    #   /build/source/test_unit/test_disasm.py
    "test_unit/test_disasm.py"

    # Doesn't run on non-2.7 but has global-level mis-import
    "test_unit/test_dis27.py"

    # Has Python 2 style prints
    "test/decompyle/test_nested_scopes.py"
  ];

  disabledTests = [
    # AssertionError: events did not match expectation
    "test_big_linenos"
    # AssertionError: False is not true : PYTHON VERSION 4.0 is not in magic.magics.keys
    "test_basic"
  ];

  meta = {
    description = "Python cross-version byte-code disassembler and marshal routines";
    homepage = "https://github.com/rocky/python-xdis";
    changelog = "https://github.com/rocky/python-xdis/releases/tag/6.3.0";
    license = lib.licenses.gpl2Plus;
  };
}
