{
  stdenvNoCC,
  fetchFromGitHub,
  lib,
}:

stdenvNoCC.mkDerivation {
  pname = "fzf-tab-completion";
  version = "0-unstable-2026-07-31";

  src = fetchFromGitHub {
    owner = "lincheney";
    repo = "fzf-tab-completion";
    rev = "7014e0a7cd68fe3530e2f58c45740d17e98f05b8";
    hash = "sha256-qxHvd91QOv4LATikWGaL4AqEM52volP8TCYXhpZKtsA=";
  };

  postInstall = ''
    mkdir -p $out/share/fzf-tab-completion
    cp -r bash zsh $out/share/fzf-tab-completion
    install -D node/fzf-node-completion.js $out/share/fzf-tab-completion/node/fzf-node-cpmpletion.js
    install -D python/fzf_python_completion.py $out/share/fzf-tab-completion/python/fzf_python_completion.py
  '';

  meta = with lib; {
    description = "Tab completion using fzf";
    homepage = "https://github.com/lincheney/fzf-tab-completion";
    license = licenses.gpl3;
  };
}
