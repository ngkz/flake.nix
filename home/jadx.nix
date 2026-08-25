# JADX settings
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

  cfg = config.programs.jadx;

  jadxGuiScaled = pkgs.stdenv.mkDerivation {
    pname = "jadx-gui-scaled";
    version = cfg.package.version;

    buildCommand = ''
      mkdir -p $out/bin

      # Symlink share directory
      ln -s ${cfg.package}/share $out/share

      # Symlink all binaries except jadx-gui
      for f in ${cfg.package}/bin/*; do
        name="$(basename $f)"
        if [[ "$name" == "jadx-gui" ]]; then
          continue
        fi
        ln -s "$f" "$out/bin/$name"
      done

      # Replace jadx-gui with wrapper that sets dynamic UI scale
      cat > "$out/bin/jadx-gui" << 'INNEREOF'
      #!${pkgs.runtimeShell}
      dpi=$(${pkgs.xrdb}/bin/xrdb -query 2>/dev/null | ${pkgs.gnugrep}/bin/grep -oP 'Xft\.dpi:\s*\K\d+' || echo 96)
      scale=$(${pkgs.gawk}/bin/awk "BEGIN {printf \"%.1f\", $dpi / 96}")
      export _JAVA_OPTIONS="-Dsun.java2d.uiScale=$scale"
      exec ${cfg.package}/bin/jadx-gui "$@"
      INNEREOF
      chmod +x "$out/bin/jadx-gui"
    '';

    meta = cfg.package.meta // {
      description = "JADX GUI with dynamic UI scale";
    };
  };

in
{
  imports = [ ./tmpfs-as-home.nix ];

  options.programs.jadx = {
    enable = mkEnableOption "jadx GUI settings";

    package = mkOption {
      type = types.package;
      default = pkgs.jadx;
      defaultText = lib.literalExpression "pkgs.jadx";
      description = "JADX package to use.";
    };

    enableHiDPIHack = mkEnableOption "dynamic UI scale for jadx-gui";

    guiSettings = mkOption {
      type = types.attrs;
      default = { };
      example = {
        editorTheme = "monokai";
        lafTheme = "FlatLaf Dark";
      };
      description = ''
        Key-value pairs to merge into jadx GUI settings file
        ({file}`$XDG_CONFIG_HOME/jadx/gui.json`).
        Values are deeply merged with the existing config.
      '';
    };

    plugins = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "github:zinja-coder:jadx-ai-mcp" ];
      description = ''
        List of jadx plugins to manage.
        Each entry is a plugin identifier (e.g. `github:owner/repo` or `file:path/to/plugin.jar`).
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = if cfg.enableHiDPIHack then [ jadxGuiScaled ] else [ cfg.package ];

    tmpfs-as-home.persistentDirs = [
      ".cache/jadx"
    ];

    home.activation.jadxPlugins = lib.hm.dag.entryAfter [ "writeBoundary" ] (''
      plugin_dir=${lib.escapeShellArg config.xdg.configHome}/jadx/plugins
      plugins_json="$plugin_dir/plugins.json"
      expected_json="$plugin_dir/hm-managed-plugins.json"

      run mkdir -p "$plugin_dir"

      if [[ -f "$plugins_json" ]]; then
        installed_json=$(${lib.getExe pkgs.jq} -c '.installed // [] | map({pluginId, locationId})' "$plugins_json")
      else
        installed_json="[]"
      fi

      old_expected="[]"
      if [[ -f "$expected_json" ]]; then
        old_expected=$(cat "$expected_json")
      fi

      new_expected=${lib.escapeShellArg (lib.generators.toJSON { } cfg.plugins)}

      to_install=$(echo "$new_expected" | ${lib.getExe pkgs.jq} -r --argjson installed "$installed_json" \
        'map(select(IN($installed[].locationId) | not)) | .[]')

      to_uninstall=$(jq -n --argjson prev "$old_expected" --argjson current "$new_expected" --argjson installed "$installed_json" \
        '$prev | map(. as $p | select(IN($current[]) | not) | select($installed | any(.pluginId == $p))) | .[]')

      if [[ -n "$to_uninstall" ]]; then
        echo "$to_uninstall" | while read -r plugin; do
          run ${lib.getExe cfg.package} plugins --uninstall "$plugin"
        done
      fi

      if [[ -n "$to_install" ]]; then
        echo "$to_install" | while read -r plugin; do
          run ${lib.getExe cfg.package} plugins --install "$plugin"
        done
      fi

      if [[ -v DRY_RUN ]]; then
        echo "echo ${lib.escapeShellArg (lib.generators.toJSON { } cfg.plugins)} > '$expected_json'"
      else
        echo ${lib.escapeShellArg (lib.generators.toJSON { } cfg.plugins)} > "$expected_json"
      fi

      unset plugin_dir plugins_json expected_json installed_json old_expected new_expected to_install to_uninstall
    '');

    home.activation.jadxGuiSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] (
      lib.optionalString (cfg.guiSettings != { }) ''
        gui_json="${lib.escapeShellArg config.xdg.configHome}/jadx/gui.json"

        # Ensure config directory exists
        run mkdir -p "$(dirname "$gui_json")"

        # Create a temporary file with the merged settings
        merged=$(mktemp)
        trap "rm -f $merged" EXIT

        # Read existing config, or create empty object
        if [[ -f "$gui_json" ]]; then
          cat "$gui_json"
        else
          echo '{}'
        fi | ${lib.getExe pkgs.jq} \
          --argjson new ${lib.escapeShellArg (lib.generators.toJSON { } cfg.guiSettings)} \
          '. * $new' > "$merged"

        # Only write if changed
        if ! diff -q "$gui_json" "$merged" >/dev/null 2>&1; then
          run mv "$merged" "$gui_json"
          run chmod 644 "$gui_json"
          echo "jadx GUI settings updated"
        else
          rm -f "$merged"
        fi

        unset gui_json merged
      ''
    );
  };
}
