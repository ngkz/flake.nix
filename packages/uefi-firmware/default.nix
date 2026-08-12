# uefi-firmware - UEFI firmware parser
#
# Built from the upstream GitHub source repo (theopolis/uefi-firmware-parser)
# at the v1.16 tag. The repo uses setuptools-scm for versioning, but
# fetchFromGitHub strips the .git directory, so SETUPTOOLS_SCM_PRETEND_VERSION
# pins the version setuptools-scm would otherwise derive from git history.
{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  setuptools-scm,
}:

buildPythonPackage rec {
  pname = "uefi-firmware";
  version = "1.16";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "theopolis";
    repo = "uefi-firmware-parser";
    tag = "v${version}";
    hash = "sha256-2vYTOC7cOiQXPMhYM+hqmFyCJeXCkx6RSxgaTIZqbds=";
  };

  build-system = [
    setuptools
    setuptools-scm
  ];

  # fetchFromGitHub leaves no .git history for setuptools-scm to read; pretend
  # the version it would derive.
  env.SETUPTOOLS_SCM_PRETEND_VERSION = version;

  # upstream depends on `future` for py2 compat (`from builtins import bytes`),
  # but `future` is broken on python 3.13 and the builtins import works natively
  # on py3, so drop the dependency.
  postPatch = ''
    substituteInPlace setup.py \
      --replace-fail 'install_requires=["future"]' 'install_requires=[]'
  '';

  doCheck = false;

  pythonImportsCheck = [ "uefi_firmware" ];

  meta = {
    description = "Various data structures and parsing tools for UEFI firmware";
    homepage = "https://github.com/theopolis/uefi-firmware-parser";
    license = lib.licenses.bsd3;
    platforms = lib.platforms.unix;
  };
}
