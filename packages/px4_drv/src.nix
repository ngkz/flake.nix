{ fetchFromGitHub }:
rec {
  version = "0.6.1";
  src = fetchFromGitHub {
    owner = "tsukumijima";
    repo = "px4_drv";
    rev = "v${version}";
    hash = "sha256-YdB2kiVhYLi8TxZVL9eCksYtvri82Ybdlbe6uthkU/c=";
  };
}
