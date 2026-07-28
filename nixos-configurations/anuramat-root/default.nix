{
  inputs,
  ...
}:
{
  imports = [
    inputs.self.nixosModules.default
    inputs.self.nixosModules.anuramat
    ./web
    ./hardware-configuration.nix
  ];

  home-manager.users.anuramat = {
    imports = [ inputs.self.homeModules.nixvim ];
    programs.nixvim = {
      enable = true;
      defaultEditor = true;
      imports = [ inputs.self.nixvimModules.base ];
    };
  };

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/vda";
  nix.distributedBuilds = true;
  system.stateVersion = "24.11";
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 16 * 1024;
    }
  ];
}
