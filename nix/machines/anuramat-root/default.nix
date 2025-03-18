# vim: fdm=marker fdl=0
{ config, ... }:
let
  home = config.users.users.${config.user}.home;
in
{
  # basic {{{1
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/vda";
  nix.distributedBuilds = true;
  system.stateVersion = "24.11";
  home-manager.users.${config.user}.home.stateVersion = "24.11";
  imports = [
    ./hardware-configuration.nix
  ];
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 16 * 1024;
    }
  ];

  # web {{{1
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
  services.static-web-server = {
    enable = true;
    listen = "[::]:80";
    root = "${home}/public";
    configuration = {
      general = {
        directory-listing = true;
      };
    };
  };
}
