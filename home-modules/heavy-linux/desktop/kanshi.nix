{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkOption types;

  cfg = config.services.kanshi;

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
      mako.settings.output = out.int;
      kanshi = {
        enable = true;
        settings =
          let

            profiles =
              let
                home = {
                  criteria = "Dell Inc. DELL S2722QC 192SH24";
                  scale = 1.5;
                  adaptiveSync = false;
                  position = "0,-99999";
                };
                generic = {
                  criteria = "*";
                  position = "0,-99999";
                };
                audimax = {
                  criteria = "PNP(LTM) RallyBar Mini 0x88888800";
                  scale = 1.0;
                  position = "0,-99999";
                };
                builtinDisplay = cfg.builtinDisplay // {
                  position = "0,0";
                };
              in
              {
                # alphabetic priority

                "p0" = [
                  builtinDisplay
                ];
                "p1-home" = [
                  builtinDisplay
                  home
                ];
                "p2-audimax" = [
                  builtinDisplay
                  audimax
                ];
                "p3-generic" = [
                  builtinDisplay
                  generic
                ];
              };

          in
          lib.optionals (cfg.builtinDisplay != null) (
            lib.mapAttrsToList (n: v: {
              profile = {
                name = n;
                outputs = v;
              };
            }) profiles
          );
      };
    };
  };
}
