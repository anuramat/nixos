{ config, ... }:
{
  config.server = true;
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
}
