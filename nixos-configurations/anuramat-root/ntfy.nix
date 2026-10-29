# push notifications to the phone; tailnet-only, iOS push goes through the
# ntfy.sh relay, which only gets message IDs
{ inputs, ... }:
let
  inherit (inputs.self.consts.ntfy) host port;
in
{
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ port ];
  services.ntfy-sh = {
    enable = true;
    settings = {
      base-url = "http://${host}:${toString port}";
      listen-http = ":${toString port}";
      upstream-base-url = "https://ntfy.sh";
      # long enough for the phone to fetch each message after the push
      cache-duration = "3h";
    };
  };
}
