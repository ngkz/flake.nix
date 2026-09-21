{ fetchFromGitHub }:
rec {
  version = "0.6.0";
  src = fetchFromGitHub {
    owner = "tsukumijima";
    repo = "px4_drv";
    rev = "v${version}";
    hash = "sha256-8cx6JwBcZ6HXYbKQxxA3yP1kmkMWOrAZW4N21eDVbqI=";
  };
}
