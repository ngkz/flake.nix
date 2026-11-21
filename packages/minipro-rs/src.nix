# Source of minipro-rs: Rust reimplementation of the minipro chip-programmer
# utility (CLI workspace in crates/, Tauri GUI in gui/).
{ fetchFromGitLab }:
rec {
  version = "0.14.1";
  rev = "v0.14.1";

  src = fetchFromGitLab {
    domain = "gitlab.com";
    owner = "arcturus8081";
    repo = "minipro-rs";
    inherit rev;
    hash = "sha256-Sr+U0DVGZy4bxG/7I1aLx0VPDImhyCWon3RleQFhMB4=";
  };
}
