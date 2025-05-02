{ helpers, lib, ... }:
let
  root = "ctrl.sn";
  domain = "bin.ctrl.sn";
  port = "8081";
in
{
  config = lib.mkMerge [
    (helpers.proxy domain port)
    (helpers.acmeExtra root domain)
    ({
      services.wastebin = {
        enable = true;
        settings = {
          WASTEBIN_BASE_URL = "https://${domain}";
          WASTEBIN_ADDRESS_PORT = "127.0.0.1:${port}";
        };
      };
    })
  ];
}
