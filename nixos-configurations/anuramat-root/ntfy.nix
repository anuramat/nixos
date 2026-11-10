# notify-forward's message bus between the hosts; tailnet-only
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
    };
  };
}
