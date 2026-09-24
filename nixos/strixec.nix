# EC fan control for the Minisforum MS-S1 MAX (strixec)
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    types
    optional
    mkOption
    mkIf
    mkEnableOption
    literalExpression
    ;

  cfg = config.services.strixec;

  # Must match PROFILES in bin/strixec-setcurve.
  profiles = [
    "ultrasilenzioso"
    "silenzioso"
    "leggero"
    "bilanciato"
    "aggressivo"
    "stock"
  ];

  setCurve = "${cfg.cli.package}/bin/strixec-setcurve";

  rule = ''
    // Apply fan profiles with pkexec, no password for users in 'wheel'.
    polkit.addRule(function(action, subject) {
        if (action.id == "org.freedesktop.policykit.exec" &&
            action.lookup("program") == "${setCurve}" &&
            subject.isInGroup("wheel")) {
            return polkit.Result.YES;
        }
    });
  '';
in
{
  options.services.strixec = {
    enable = mkEnableOption "strixec EC fan control for the Minisforum MS-S1 MAX";

    curve = mkOption {
      type = types.nullOr (types.enum profiles);
      default = null;
      description = ''
        Fan-curve profile to write into the EC table at boot. The firmware
        resets to its stock curve on every power cycle, so set this to keep the
        chosen profile without logging in. When null, no profile is applied
        automatically.
      '';
    };

    cli.package = mkOption {
      type = types.package;
      default = pkgs.ngkz.strixec-cli;
      defaultText = literalExpression "pkgs.ngkz.strixec-cli";
      description = "Package providing {command}`strixec-setcurve` and {command}`strixec-findfan`.";
    };

    gui.enable = mkEnableOption "the strixec GUI and its desktop launcher";

    gui.package = mkOption {
      type = types.package;
      default = pkgs.ngkz.strixec-gui.override {
        strixec-cli = cfg.cli.package;
      };
      defaultText = literalExpression ''
        pkgs.ngkz.strixec-gui.override { strixec-cli = cfg.cli.package; }
      '';
      description = ''
        GUI package to install. {command}`strixec-setcurve` is baked into the
        GUI at build time, so the default re-points it at
        {option}`services.strixec.cli.package`.
      '';
    };

    module.package = mkOption {
      type = types.package;
      default = pkgs.callPackage ../packages/strixec/module.nix {
        linuxPackages = config.boot.kernelPackages;
      };
      defaultText = literalExpression ''
        pkgs.callPackage ../packages/strixec/module.nix {
          linuxPackages = config.boot.kernelPackages;
        }
      '';
      description = ''
        Package providing {file}`strixec.ko`. It has to be built for the kernel
        the system boots.
      '';
    };
  };

  config = mkIf cfg.enable {
    security.polkit.enable = true;

    # polkitd reads the rules from 10-nixos.rules. The rule names the wrapped
    # CLI in the store, so it has to reference the same package pkexec calls.
    security.polkit.extraConfig = lib.mkAfter rule;

    environment.systemPackages = [
      cfg.cli.package
    ]
    ++ optional cfg.gui.enable cfg.gui.package;

    # The module registers /dev/strixec (mode 0600, root only).
    boot.extraModulePackages = [ cfg.module.package ];
    boot.kernelModules = [ "strixec" ];

    systemd.services.strixec-curve = mkIf (cfg.curve != null) {
      description = "Apply the ${cfg.curve} fan curve (Minisforum MS-S1 MAX)";
      after = [ "systemd-modules-load.service" ];
      unitConfig.ConditionPathExists = "/dev/strixec";
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${setCurve} ${cfg.curve}";
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
}
