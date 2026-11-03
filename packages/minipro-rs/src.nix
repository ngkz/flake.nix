# Source of minipro-rs: Rust reimplementation of the minipro chip-programmer
# utility (CLI workspace in crates/, Tauri GUI in gui/).
{ fetchFromGitLab }:
rec {
  # Pinned past the v0.9.0 tag: the T48 fixes on the upstream
  # fix/t48-read-path branch (firmware minimum, ported hardware self-test,
  # EP2-only payload for >64-byte transfers, pin-test gating) are unreleased.
  # Drop back to a tag once upstream cuts v0.9.1.
  rev = "e8201c4fcc97f9ccb607b94250b92ff66856099d";
  version = "0.9.0-unstable-2026-11-02";

  src = fetchFromGitLab {
    domain = "gitlab.com";
    owner = "arcturus8081";
    repo = "minipro-rs";
    inherit rev;
    hash = "sha256-vqIXUPN81JHWdlAUr98hf7LM+BEKdb4I9LF2McgMVFg=";
  };
}
