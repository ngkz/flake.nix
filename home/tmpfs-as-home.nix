# tmpfs as root: home-manager edition
{ lib, config, ... }:
let
  inherit (lib)
    hm
    concatStringsSep
    escapeShellArg
    mkOption
    types
    unique
    mkEnableOption
    mkIf
    ;
in
{
  options.tmpfs-as-home = {
    enable = mkEnableOption "Tmpfs as home setup";

    storage = mkOption {
      type = types.strMatching "^/.*[^/]$";
      description = "Path of persistent storage";
    };

    persistentDirs = mkOption {
      type = with types; listOf str;
      default = [ ];
      description = "Directories which should be stored in the persistent storage.";
    };

    persistentFiles = mkOption {
      type = with types; listOf str;
      default = [ ];
      description = "Files which should be stored in the persistent storage.";
    };
  };

  config =
    let
      cfg = config.tmpfs-as-home;
      files = cfg.persistentFiles;
      dirs = cfg.persistentDirs;
      storage = cfg.storage;
      storageDirs = map (path: "${storage}/${path}") (unique ((map dirOf files) ++ dirs));
    in
    mkIf cfg.enable {
      # TODO Remove symlinks from the old generation that are not in the new generation
      # like home-manager.
      home.activation.tmpfs-as-home =
        hm.dag.entryBetween
          [
            # run libvirt configuration after tmpfs-as-home setup
            "NixVirt"

            "linkGeneration"
          ]
          [ "writeBoundary" ]
          (
            concatStringsSep "\n" (
              (map (path: "run mkdir -p ${escapeShellArg path}") storageDirs)
              ++ (map (path: ''
                run mkdir -p $(dirname ~/${escapeShellArg path})
                run ln -fnTs ${escapeShellArg (storage + "/" + path)} ~/${escapeShellArg path}
              '') (files ++ dirs))
            )
          );
    };
}
