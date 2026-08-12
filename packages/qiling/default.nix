# Qiling advanced binary emulation framework
# Copied from nixpkgs (pkgs/development/python-modules/qiling) with the
# `broken = true` flag removed. Upstream marked it broken claiming it "No
# longer builds using current cmake" (keystone-engine dependency), but the
# build, import and a runtime shellcode emulation test all pass on 26.05.
{
  lib,
  buildPythonPackage,
  capstone,
  fetchPypi,
  gevent,
  keystone-engine,
  multiprocess,
  pefile,
  pyelftools,
  python-fx,
  python-registry,
  pyyaml,
  questionary,
  termcolor,
  unicorn,
}:

buildPythonPackage (finalAttrs: {
  pname = "qiling";
  version = "1.4.6";
  format = "setuptools";

  src = fetchPypi {
    inherit (finalAttrs) pname version;
    hash = "sha256-l3WQBlJic4lXCe5Z1FmoxaqOblE7uAaW2gG/nTn84Kc=";
  };

  propagatedBuildInputs = [
    capstone
    gevent
    keystone-engine
    multiprocess
    pefile
    pyelftools
    python-fx
    python-registry
    pyyaml
    termcolor
    questionary
    unicorn
  ];

  # Tests are broken (attempt to import a file that tells you not to import it,
  # amongst other things)
  doCheck = false;

  pythonImportsCheck = [ "qiling" ];

  meta = {
    description = "Qiling Advanced Binary Emulation Framework";
    homepage = "https://qiling.io/";
    changelog = "https://github.com/qilingframework/qiling/releases/tag/${finalAttrs.version}";
    license = lib.licenses.gpl2Only;
    platforms = lib.platforms.unix;
  };
})
