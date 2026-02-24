{
  pkgs,
  config,
  lib,
  ...
}:
let

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
                t480 = {
                  criteria = "LG Display 0x0521 Unknown";
                  position = "0,0";
                };
                ll7 = {
                  criteria = "California Institute of Technology 0x1626 0x00006002";
                  position = "0,0";
                  scale = 1.5;
                };
                f12 = {
                  criteria = "BOE NV122WUM-N42 Unknown";
                  scale = 1.0;
                  position = "0,0";
                };
                home = {
                  criteria = "Dell Inc. DELL S2722QC 192SH24";
                  scale = 1.5;
                  adaptiveSync = false;
                };
                generic = {
                  criteria = "*";
                  position = "0,-99999";
                };
              in
              {
                # alphabetic priority

                ll7-0 = [
                  (ll7 // { mode = "3200x2000@60Hz"; })
                ];
                ll7-1-home = [
                  (ll7 // { scale = 2.0; })
                  (home // { position = "1600,0"; })
                ];
                ll7-2-generic = [
                  ll7
                  generic
                ];

                t480-0 = [
                  t480
                ];
                t480-1-home = [
                  t480
                  (home // { position = "0,-2000"; })
                ];
                t480-2-generic = [
                  t480
                  generic
                ];

                f12-0 = [
                  f12
                ];
                f12-1-home = [
                  f12
                  (home // { position = "0,-2000"; })
                ];
                f12-2-generic = [
                  f12
                  generic
                ];
              };

          in
          lib.mapAttrsToList (n: v: {
            profile = {
              name = n;
              outputs = v;
              exec = config.services.kanshi.exec;
            };
          }) profiles;
      };
    };
  };
  options.services.kanshi.exec = lib.mkOption {
    type = lib.types.listOf lib.types.str;
  };
}
