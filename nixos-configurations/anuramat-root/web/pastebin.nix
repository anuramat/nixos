{ hax, lib, ... }:
let
  w = {
    root = "ctrl.sn";
    domain = "bin.ctrl.sn";
    port = "8081";
    noRobots = true;
  };
in
lib.mkMerge (
  (hax.web.serve w)
  ++ [
    ({
      services.wastebin = {
        enable = true;
        settings = {
          WASTEBIN_BASE_URL = "https://${w.domain}";
          WASTEBIN_ADDRESS_PORT = "127.0.0.1:${w.port}";
          WASTEBIN_MAX_BODY_SIZE = 1024 * 1024;
        };
      };
    })
  ]
)
