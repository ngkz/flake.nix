{
  lib,
  vimUtils,
  fetchFromGitHub,
  ...
}:
let
  inherit (vimUtils) buildVimPlugin;
in
buildVimPlugin {
  name = "flygrep-vim";
  src = fetchFromGitHub {
    owner = "wsdjeg";
    repo = "FlyGrep.vim";
    rev = "e06b5a99db4a888c3c0ed497e8ac209ec998051f";
    hash = "sha256-5BWqewF05zEGfKYOTr8OjpFSQYA1c2I9QXX3LtbcU74=";
  };
  nvimSkipModules = [ "spacevim.plugin.flygrep" ];

  meta = with lib; {
    description = "Asynchronously fly grep in vim";
    homepage = "https://github.com/wsdjeg/FlyGrep.vim";
    license = licenses.gpl3Only;
    platforms = platforms.unix;
  };
}
