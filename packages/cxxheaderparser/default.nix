# cxxheaderparser - Modern C++ header parser
# angr 10.0.2 reads cxxheaderparser.types.MemberPointer, which only exists in
# 2.0+. nixpkgs (stable and unstable) ships 1.9.2 or older, and angr does not
# pin the version, so bump it here.
{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  hatch-vcs,
  hatchling,
}:

buildPythonPackage rec {
  pname = "cxxheaderparser";
  version = "2.0.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "robotpy";
    repo = "cxxheaderparser";
    tag = version;
    hash = "sha256-YF7ImKD+QsGb6IxntySHSYQafrDJw9fFD5TwShs5Q18=";
  };

  postPatch = ''
    # version.py is generated based on latest git tag
    echo "__version__ = '${version}'" > cxxheaderparser/version.py
  '';

  build-system = [
    hatch-vcs
    hatchling
  ];

  doCheck = false;

  pythonImportsCheck = [ "cxxheaderparser" ];

  meta = {
    description = "Modern C++ header parser";
    homepage = "https://github.com/robotpy/cxxheaderparser";
    changelog = "https://github.com/robotpy/cxxheaderparser/releases/tag/${src.tag}";
    license = lib.licenses.bsd3;
    platforms = lib.platforms.unix;
  };
}
