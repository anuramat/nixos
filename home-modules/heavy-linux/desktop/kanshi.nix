{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkOption types;

  cfg = config.services.kanshi;
  hasBuiltin = cfg.builtinDisplay != null;

  displayType = types.submodule {
    freeformType = types.attrsOf types.anything;
    options.criteria = mkOption { type = types.str; };
  };

  out = {
    int = "eDP-1";
    ext = [
      "DP-1"
      "DP-2"
      "DP-3"
      "DP-4"
      "HDMI-A-2"
      "HDMI-A-3"
      "HEADLESS-1"
    ];
  };

in

{
  options.services.kanshi.builtinDisplay = mkOption {
    type = types.nullOr displayType;
    default = null;
  };

  config = {
    systemd.user.services.kanshi.Service = {
      Restart = "always";
      RestartSec = 10;
    };
    services = {
      mako.settings.output = lib.mkIf hasBuiltin out.int;
      kanshi = {
        enable = true;
        settings =
          let

            profiles =
              let
                # NOTE negative/larger y values break xwayland
                extPos = if hasBuiltin then "0,9999" else "0,0";
                home = {
                  criteria = "Dell Inc. DELL S2722QC 192SH24";
                  scale = 1.5;
                  adaptiveSync = false;
                  position = extPos;
                };
                generic = {
                  criteria = "*";
                  position = extPos;
                };
                audimax = {
                  criteria = "PNP(LTM) RallyBar Mini 0x88888800";
                  scale = 1.0;
                  position = extPos;
                };
                builtin = lib.optional hasBuiltin (cfg.builtinDisplay // { position = "0,0"; });
              in
              {
                # alphabetic priority

                "p1-home" = builtin ++ [ home ];
                "p2-audimax" = builtin ++ [ audimax ];
                "p3-generic" = builtin ++ [ generic ];
              }
              // lib.optionalAttrs hasBuiltin { "p0" = builtin; };

          in
          lib.mapAttrsToList (n: v: {
            profile = {
              name = n;
              outputs = v;
            };
          }) profiles;
      };
    };
  };
}
