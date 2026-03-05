{
  inputs,
  ...
}:
{
  system.stateVersion = "25.05";
  home-manager.users.anuramat.home.stateVersion = "25.05";

  # swap partition
  boot.initrd.luks.devices."luks-ffc8e21f-2272-442f-8258-30742e29e1f0".device =
    "/dev/disk/by-uuid/ffc8e21f-2272-442f-8258-30742e29e1f0";

  nix.distributedBuilds = true;

  services.keyd.keyboards.main.ids = [ "0001:0001:70533846" ];

  networking.hostName = "anuramat-f12";

  imports = [
    inputs.self.nixosModules.default
    inputs.self.nixosModules.local
    inputs.self.nixosModules.laptop
    inputs.self.nixosModules.anuramat
    inputs.nixos-hardware.nixosModules.framework-12-13th-gen-intel
    ./hardware-configuration.nix
  ];

  programs.captive-browser.interface = "wlp0s20f3";
}
