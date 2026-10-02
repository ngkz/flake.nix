# Source of minipro-rs: Rust reimplementation of the minipro chip-programmer
# utility (CLI workspace in crates/, Tauri GUI in gui/).
{ fetchFromGitLab }:
rec {
  version = "0.9.0";

  src = fetchFromGitLab {
    domain = "gitlab.com";
    owner = "arcturus8081";
    repo = "minipro-rs";
    rev = "v${version}";
    hash = "sha256-83gs25tqpuU5pwrWOvtG9o3QJhAY9gV92ghnOxrKfjY=";
  };
}
