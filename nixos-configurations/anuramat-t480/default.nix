{
  inputs,
  config,
  ...
}:
{
  nix.distributedBuilds = true;
  system.stateVersion = "24.05";
  home-manager.users.anuramat.home.stateVersion = "24.11";
  services.keyd.keyboards.main.ids = [
    # same keyboard
    "0001:0001:a38e6885"
    "0001:0001:70533846"
  ];

  networking.hostName = "anuramat-t480";

  imports = [
    inputs.self.nixosModules.default
    inputs.self.nixosModules.local
    inputs.self.nixosModules.anuramat
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t480
    ./hardware-configuration.nix
  ];

  services.tlp = {
    enable = true;
    settings = {
      CPU_MIN_PERF_ON_AC = 100;
      CPU_MAX_PERF_ON_AC = 100;
      CPU_MIN_PERF_ON_BAT = 0;
      CPU_MAX_PERF_ON_BAT = 100;
    };
  };

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 32 * 1024;
    }
  ];

  programs.captive-browser.interface = "wlp3s0";
}
