# Source of "MS S1 Max fans control" (kernel module + CLI + GUI)
{ fetchFromGitHub }:
rec {
  # Upstream has no releases. Track the program version the GUI reports
  # (bin/strixec-gui VERSION) plus the date of the packaged commit.
  upstreamVersion = "1.1.0";
  version = "${upstreamVersion}-unstable-2026-09-05";

  src = fetchFromGitHub {
    owner = "raimondomartire";
    repo = "ms-s1-max-fans-control";
    rev = "8107ca05cc7915439a350943e5fe133dedf5621c";
    hash = "sha256-FzD4BJ9YNLESDmRrUjCRoggSAHhq6677U43pkCpJDOI=";
  };
}
