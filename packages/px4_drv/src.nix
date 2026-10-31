{ fetchFromGitHub }:
rec {
  version = "0.7.0";
  src = fetchFromGitHub {
    owner = "tsukumijima";
    repo = "px4_drv";
    rev = "v${version}";
    hash = "sha256-vuT89Gexk/OeUMyPtDSdcHyN7/oJuLoAjKm6aI1TQJE=";
  };
}
