{ inputs, ... }:
{
  system.stateVersion = "24.05";
  nix.distributedBuilds = true;

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
