{
  inputs,
  ...
}:
{
  nix.distributedBuilds = false;
  system.stateVersion = "25.11";
  home-manager.users.anuramat.home.stateVersion = "25.11";
  networking.hostName = "anuramat-bgm5";

  imports = [
    inputs.self.nixosModules.default
    inputs.self.nixosModules.local
    inputs.self.nixosModules.anuramat
    ./hardware-configuration.nix
  ];

  programs.captive-browser.interface = "wlp195s0";
}
