{
  inputs,
  ...
}:
{
  nix.distributedBuilds = true;
  system.stateVersion = "25.05";
  home-manager.users.anuramat.home.stateVersion = "25.05";
  services.keyd.keyboards.main.ids = [
    "0001:0001:70533846"
  ];

  networking.hostName = "anuramat-f12";

  imports = [
    inputs.self.nixosModules.default
    inputs.self.nixosModules.local
    inputs.self.nixosModules.anuramat
    inputs.nixos-hardware.nixosModules.framework-12-13th-gen-intel
    ./hardware-configuration.nix
  ];

  # services.tlp = {
  #   enable = true;
  #   settings = {
  #     CPU_MIN_PERF_ON_AC = 100;
  #     CPU_MAX_PERF_ON_AC = 100;
  #     CPU_MIN_PERF_ON_BAT = 50;
  #     CPU_MAX_PERF_ON_BAT = 100;
  #   };
  # };

  # swapDevices = [
  #   {
  #     device = "/var/lib/swapfile";
  #     size = 32 * 1024;
  #   }
  # ];

  programs.captive-browser.interface = "wlp0s20f3";
}
