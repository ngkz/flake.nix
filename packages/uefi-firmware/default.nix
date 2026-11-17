# uefi-firmware - UEFI firmware parser
#
# Built from the upstream GitHub source repo (theopolis/uefi-firmware-parser)
# at the v<version> tag. The repo uses setuptools-scm for versioning, but
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
  version = "1.17";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "theopolis";
    repo = "uefi-firmware-parser";
    tag = "v${version}";
    hash = "sha256-6iOJ4Si6pD6QPnfv7Q7aR+nDgHovqcZL6Wp/Dkb64Uo=";
  };

  build-system = [
    setuptools
    setuptools-scm
  ];

  # fetchFromGitHub leaves no .git history for setuptools-scm to read; pretend
  # the version it would derive.
  env.SETUPTOOLS_SCM_PRETEND_VERSION = version;

  doCheck = false;

  # the compression extension is compiled from the bundled C sources, so check
  # it imports as well.
  pythonImportsCheck = [
    "uefi_firmware"
    "uefi_firmware.efi_compressor"
  ];

  meta = {
    description = "Various data structures and parsing tools for UEFI firmware";
    homepage = "https://github.com/theopolis/uefi-firmware-parser";
    license = lib.licenses.bsd3;
    platforms = lib.platforms.unix;
  };
}
