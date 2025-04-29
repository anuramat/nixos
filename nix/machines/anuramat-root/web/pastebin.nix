{ helpers, ... }:
let
  domain = "bin.ctrl.sn";
  port = "8081";
in
(helpers.proxy domain port)
// {
  services.wastebin = {
    enable = true;
    settings = {
      WASTEBIN_BASE_URL = "https://${domain}";
      WASTEBIN_ADDRESS_PORT = "127.0.0.1:${port}";
    };
  };
}
