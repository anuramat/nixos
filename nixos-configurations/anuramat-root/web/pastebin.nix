_:
let
  w = {
    root = "ctrl.sn";
    domain = "bin.ctrl.sn";
    port = "8081";
  };
in
{
  web.sites = [ w ];
  services.wastebin = {
    enable = true;
    settings = {
      WASTEBIN_BASE_URL = "https://${w.domain}";
      WASTEBIN_ADDRESS_PORT = "127.0.0.1:${w.port}";
      WASTEBIN_MAX_BODY_SIZE = 1024 * 1024;
    };
  };
}
