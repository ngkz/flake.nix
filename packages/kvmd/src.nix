{ fetchFromGitHub }:
rec {
  version = "4.180";
  src = fetchFromGitHub {
    owner = "pikvm";
    repo = "kvmd";
    rev = "v${version}";
    hash = "sha256-SsGrshhntiktUdA/tcIKcnlN6WtiA9vq5we7l+1mYw8=";
  };
}
