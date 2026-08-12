{ fetchFromGitHub }:
rec {
  version = "0.5.6";
  src = fetchFromGitHub {
    owner = "tsukumijima";
    repo = "px4_drv";
    rev = "v${version}";
    hash = "sha256-E/hGh2F6xsNHJlf6P5RjfT7vCYtpZC/6opiPqMVEsNk=";
  };
}
