{ config, ... }:
{
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
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/vda";
}
