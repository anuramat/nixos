{ helpers, lib, ... }:
let
  w = {
    root = "ctrl.sn";
    domain = "bin.ctrl.sn";
    port = "8081";
  };
in
lib.mkMerge (
  (helpers.serve w)
  ++ [
    ({
      services.wastebin = {
        enable = true;
        settings = {
          WASTEBIN_BASE_URL = "https://${w.domain}";
          WASTEBIN_ADDRESS_PORT = "127.0.0.1:${w.port}";
        };
      };
    })
  ]
)
