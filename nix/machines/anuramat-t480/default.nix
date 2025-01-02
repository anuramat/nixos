{ inputs, local, ... }:
{
  system.stateVersion = "24.05";

  imports = [
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t480
    ./hardware-configuration.nix
    local
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
