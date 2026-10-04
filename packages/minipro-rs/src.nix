# Source of minipro-rs: Rust reimplementation of the minipro chip-programmer
# utility (CLI workspace in crates/, Tauri GUI in gui/).
{ fetchFromGitLab }:
rec {
  # Pinned past the v0.9.0 tag: the two T48 fixes (firmware minimum and the
  # ported upstream hardware self-test) are unreleased. Drop back to a tag
  # once upstream cuts v0.9.1.
  rev = "18dd6e754a81e59a286b52087be08b4c290d7492";
  version = "0.9.0-unstable-2026-10-03";

  src = fetchFromGitLab {
    domain = "gitlab.com";
    owner = "arcturus8081";
    repo = "minipro-rs";
    inherit rev;
    hash = "sha256-H5DNJQM0r7zOSDkyM4B2n5zrmAn9PV+nJCdakf5BZME=";
  };
}
