let
  immichPort = 2283;
in
{
  services.immich = {
    enable = true;
    host = "0.0.0.0";
    port = immichPort;
  };
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
    immichPort
  ];
  home-manager.users.anuramat = {
    programs.niri.settings.input.touchpad.tap = true;
    services.codexRemote.enable = true;
  };
}
