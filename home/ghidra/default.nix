# Ghidra config and packages
{
  options,
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.programs.ghidra;

  inherit (lib)
    types
    mkOption
    mkIf
    mkEnableOption
    ;

  ghidraWithExt = cfg.package.withExtensions (p: cfg.extensions);

  ghidraScaled = pkgs.stdenv.mkDerivation {
    pname = "ghidra-scaled";
    version = cfg.package.version;

    buildCommand = ''
      mkdir -p $out/bin

      # Symlink share and lib directory
      ln -s ${ghidraWithExt}/share $out/share
      ln -s ${ghidraWithExt}/lib $out/lib

      # Symlink all binaries except ghidra
      for f in ${ghidraWithExt}/bin/*; do
        name="$(basename $f)"
        if [[ "$name" == "ghidra" ]]; then
          continue
        fi
        ln -s "$f" "$out/bin/$name"
      done

      # Wrap ghidra with dynamic UI scale
      cat > "$out/bin/ghidra" << 'INNEREOF'
      #!${pkgs.runtimeShell}
      dpi=$(${pkgs.xrdb}/bin/xrdb -query 2>/dev/null | ${pkgs.gnugrep}/bin/grep -oP 'Xft\.dpi:\s*\K\d+' || echo 96)
      scale=$(${pkgs.gawk}/bin/awk "BEGIN {printf \"%.1f\", $dpi / 96}")
      export _JAVA_OPTIONS="-Dsun.java2d.uiScale=$scale"
      exec ${ghidraWithExt}/bin/ghidra "$@"
      INNEREOF
      chmod +x "$out/bin/ghidra"
    '';
  };

  finalPackage = if cfg.enableHiDPIHack then ghidraScaled else ghidraWithExt;

  ghidraRpcPkg = pkgs.ngkz.ghidra-rpc.override {
    ghidra = cfg.package;
    ghidraWithExtensions = finalPackage;
  };

  ghidraRpcScaled = pkgs.stdenv.mkDerivation {
    pname = "ghidra-rpc-scaled";
    version = cfg.package.version;

    buildCommand = ''
      mkdir -p $out/bin

      # Symlink share directory
      ln -s ${ghidraWithExt}/share $out/share

      # Wrap ghidra-rpc with dynamic UI scale
      cat > "$out/bin/ghidra-rpc" << 'INNEREOF'
      #!${pkgs.runtimeShell}
      dpi=$(${pkgs.xrdb}/bin/xrdb -query 2>/dev/null | ${pkgs.gnugrep}/bin/grep -oP 'Xft\.dpi:\s*\K\d+' || echo 96)
      scale=$(${pkgs.gawk}/bin/awk "BEGIN {printf \"%.1f\", $dpi / 96}")
      export _JAVA_OPTIONS="-Dsun.java2d.uiScale=$scale"
      exec ${ghidraRpcPkg}/bin/ghidra-rpc "$@"
      INNEREOF
      chmod +x "$out/bin/ghidra-rpc"
    '';
  };

  finalRpcPackage = if cfg.enableHiDPIHack then ghidraRpcScaled else ghidraRpcPkg;

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
    package = mkOption {
      type = types.package;
      default = pkgs.ghidra;
      defaultText = lib.literalExpression "pkgs.ghidra";
      description = "Ghidra package to use.";
    };
    enableHiDPIHack = mkEnableOption "dynamic UI scale for Ghidra";
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
    enableRPC = mkEnableOption "ghidra-rpc CLI";
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = lib.all (k: lib.elem k toolTypes) (lib.attrNames cfg.keybindings);
        message = "programs.ghidra.keybindings keys must be one of: ${lib.concatStringsSep ", " toolTypes}";
      }
      {
        assertion = lib.all (k: lib.elem k toolTypes) (lib.attrNames cfg.toolOptions);
        message = "programs.ghidra.toolOptions keys must be one of: ${lib.concatStringsSep ", " toolTypes}";
      }
    ];

    programs.ghidra.keybindings = mkIf cfg.idaKeybindings {
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
        lib.optionalString (cfg.toolOptions.${toolName} != "") ''
          toolXml=$(mktemp -d)
          trap "rm -rf $toolXml" EXIT
          if [[ ! -v DRY_RUN ]]; then
            cat >"$toolXml/options.xml" << 'HEREDOC'
          ${cfg.toolOptions.${toolName}}
          HEREDOC
          fi
          run ${lib.getExe pkgs.python3} \
             ${./apply-keybindings.py} \
             merge \
             ${lib.escapeShellArg toolName} \
             "$toolXml/options.xml" \
             ${lib.escapeShellArg "${config.xdg.configHome}/ghidra/ghidra_${cfg.package.version}_NIX/tools"} \
             ${cfg.package}
        ''
      ) (lib.attrNames cfg.toolOptions))
      + (lib.concatMapStringsSep "\n" (toolName: ''
        run ${lib.getExe pkgs.python3} \
          ${./apply-keybindings.py} \
          replace \
          ${lib.escapeShellArg toolName} \
          ${lib.escapeShellArg cfg.keybindings.${toolName}} \
          ${lib.escapeShellArg "${config.xdg.configHome}/ghidra/ghidra_${cfg.package.version}_NIX/tools"} \
          ${cfg.package}
      '') (lib.attrNames cfg.keybindings))
      + (
        let
          pairs = lib.mapAttrsToList (k: v: k + "=" + v) cfg.preferences;
        in
        lib.optionalString (pairs != [ ]) ''
          run ${lib.getExe pkgs.python3} \
            ${./merge-preferences.py} \
            ${lib.escapeShellArg "${config.xdg.configHome}/ghidra/ghidra_${cfg.package.version}_NIX/preferences"} \
            ${lib.concatStringsSep " " (map lib.escapeShellArg pairs)}
        ''
      )
    );

    home.file.".cache/pwndbg/d2d/ghidra_plugin_version".text = mkIf (lib.any (
      ext: ext == pkgs.ngkz.ghidra-decomp2dbg
    ) cfg.extensions) pkgs.ngkz.ghidra-decomp2dbg.version;

    home.packages = [
      finalPackage
    ]
    ++ lib.optional cfg.enableRPC finalRpcPackage;
  };
}
