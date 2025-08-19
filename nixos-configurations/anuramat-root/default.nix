{
  inputs,
  config,
  ...
}:
{
  imports = [
    inputs.self.nixosModules.default
    inputs.self.nixosModules.anuramat
    ./web
    ./hardware-configuration.nix
  ];

  networking.hostName = "anuramat-root";

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/vda";
  nix.distributedBuilds = true;
  system.stateVersion = "24.11";
  home-manager.users.anuramat.home.stateVersion = "24.11";
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 16 * 1024;
    }
  ];
}
