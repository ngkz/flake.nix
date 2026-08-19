# Ghidra config and packages
{
  options,
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib)
    types
    mkOption
    mkIf
    mkEnableOption
    ;

  # Valid tool names for keybindings (match apply-keybindings.py)
  toolTypes = [
    "code_browser"
    "debugger"
    "emulator"
    "version_tracking"
  ];

in
{
  imports = [ ../tmpfs-as-home.nix ];

  options.programs.ghidra = {
    enable = mkEnableOption "Ghidra";
    idaKeybindings = mkOption {
      type = types.bool;
      default = false;
      description = "Apply the IDA-style ghIDA key bindings to the code browser tool.";
    };
    keybindings = mkOption {
      type = types.attrsOf types.path;
      default = { };
      example = {
        code_browser = ./my-code-browser.kbxml;
      };
      description = "Path to a .kbxml keybindings file per tool. Valid keys: ${lib.concatStringsSep ", " toolTypes}.";
    };
    preferences = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = "Key-value pairs to merge into Ghidra preferences file.";
    };
    toolOptions = mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = {
        code_browser = ''
          <CATEGORY NAME="Listing Fields">
            <STATE NAME="Bytes Field.Maximum Lines" TYPE="int" VALUE="1"/>
          </CATEGORY>
        '';
      };
      description = "XML categories to merge into Ghidra tool OPTIONS. Matches by CATEGORY NAME + element NAME.";
    };
    extensions = mkOption {
      type = types.listOf types.package;
      default = [ ];
      example = [ pkgs.ngkz.avr-ghidra-helpers ];
      description = "Ghidra extensions passed to `ghidra.withExtensions`";
    };
  };

  config = mkIf config.programs.ghidra.enable {
    assertions = [
      {
        assertion = lib.all (k: lib.elem k toolTypes) (lib.attrNames config.programs.ghidra.keybindings);
        message = "programs.ghidra.keybindings keys must be one of: ${lib.concatStringsSep ", " toolTypes}";
      }
      {
        assertion = lib.all (k: lib.elem k toolTypes) (lib.attrNames config.programs.ghidra.toolOptions);
        message = "programs.ghidra.toolOptions keys must be one of: ${lib.concatStringsSep ", " toolTypes}";
      }
    ];

    programs.ghidra.keybindings = mkIf config.programs.ghidra.idaKeybindings {
      # https://github.com/nullteilerfrei/reversing-class
      code_browser = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/nullteilerfrei/reversing-class/cb5d047b18e0a5bdbc96d17e005df0f7c8156e16/ghIDA.kbxml";
        sha256 = "a828f162f4d06da2037d6d2cb781d8358f1438befe62e9c62a18f61509e50653";
      };
    };

    tmpfs-as-home.persistentDirs = [
      ".ghidra"
      ".config/ghidra"
    ];

    home.activation.ghidraConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] (
      (lib.concatMapStringsSep "\n" (
        toolName:
        lib.optionalString (config.programs.ghidra.toolOptions.${toolName} != "") ''
          toolXml=$(mktemp -d)
          trap "rm -rf $toolXml" EXIT
          if [[ ! -v DRY_RUN ]]; then
            cat >"$toolXml/options.xml" << 'HEREDOC'
          ${config.programs.ghidra.toolOptions.${toolName}}
          HEREDOC
          fi
          run ${lib.getExe pkgs.python3} \
             ${./apply-keybindings.py} \
             merge \
             ${lib.escapeShellArg toolName} \
             "$toolXml/options.xml" \
             ${lib.escapeShellArg "${config.xdg.configHome}/ghidra/ghidra_${pkgs.ghidra.version}_NIX/tools"} \
             ${pkgs.ghidra}
        ''
      ) (lib.attrNames config.programs.ghidra.toolOptions))
      + (lib.concatMapStringsSep "\n" (toolName: ''
        run ${lib.getExe pkgs.python3} \
          ${./apply-keybindings.py} \
          replace \
          ${lib.escapeShellArg toolName} \
          ${lib.escapeShellArg config.programs.ghidra.keybindings.${toolName}} \
          ${lib.escapeShellArg "${config.xdg.configHome}/ghidra/ghidra_${pkgs.ghidra.version}_NIX/tools"} \
          ${pkgs.ghidra}
      '') (lib.attrNames config.programs.ghidra.keybindings))
      + (
        let
          pairs = lib.mapAttrsToList (k: v: k + "=" + v) config.programs.ghidra.preferences;
        in
        lib.optionalString (pairs != [ ]) ''
          run ${lib.getExe pkgs.python3} \
            ${./merge-preferences.py} \
            ${lib.escapeShellArg "${config.xdg.configHome}/ghidra/ghidra_${pkgs.ghidra.version}_NIX/preferences"} \
            ${lib.concatStringsSep " " (map lib.escapeShellArg pairs)}
        ''
      )
    );

    home.file.".cache/pwndbg/d2d/ghidra_plugin_version".text = pkgs.ngkz.ghidra-decomp2dbg.version;

    home.packages = with pkgs; [
      (ghidra.withExtensions (p: config.programs.ghidra.extensions))
    ];
  };
}
