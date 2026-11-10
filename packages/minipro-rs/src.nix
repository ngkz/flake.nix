# Source of minipro-rs: Rust reimplementation of the minipro chip-programmer
# utility (CLI workspace in crates/, Tauri GUI in gui/).
{ fetchFromGitLab }:
rec {
  version = "0.11.0";
  rev = "v0.11.0";

  src = fetchFromGitLab {
    domain = "gitlab.com";
    owner = "arcturus8081";
    repo = "minipro-rs";
    inherit rev;
    hash = "sha256-lW0L3gRYYmu3fURHrclRW4CZnzLGfzNMtvdZsX+H+2I=";
  };
}
