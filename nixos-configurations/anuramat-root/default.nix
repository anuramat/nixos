# vim: fdm=marker fdl=0
{
  inputs,
  config,
  username,
  ...
}:
{
  imports = [
    inputs.self.nixosModules.default
    inputs.self.nixosModules.anuramat
    ./web
    ./hardware-configuration.nix
  ];
  # basic {{{1
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/vda";
  nix.distributedBuilds = true;
  system.stateVersion = "24.11";
  home-manager.users.${username}.home.stateVersion = "24.11";
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 16 * 1024;
    }
  ];
}
