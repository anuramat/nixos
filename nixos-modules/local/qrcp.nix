# share files over qr
{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  port = 9000;
in
{
  environment.systemPackages = [ pkgs.qrcp ];
  networking.firewall.allowedTCPPorts = [ port ];
  home-manager.users.${inputs.self.consts.user.username}.xdg.configFile."qrcp/config.yml".text =
    lib.generators.toYAML { }
      {
        interface = "any";
        keepalive = true;
        inherit port;
      };
}
