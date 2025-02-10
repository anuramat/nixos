{ inputs, config, ... }:
{
  nix.distributedBuilds = true;
  system.stateVersion = "24.05";
  home-manager.users.${config.user}.home.stateVersion = "24.11";
  services.keyd.keyboards.main.ids = [
    "0001:0001:a38e6885"
  ];

  imports = [
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t480
    ./hardware-configuration.nix
  ];

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 32 * 1024;
    }
  ];

  # services = {
  #   tlp.settings = {
  #     CPU_MAX_PERF_ON_BAT = 30;
  #   };
  # };
}
