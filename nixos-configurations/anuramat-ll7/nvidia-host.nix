{ inputs, ... }:
{
  imports = [
    inputs.nixos-hardware.nixosModules.common-gpu-nvidia
  ];

  services.xserver.videoDrivers = [ "nvidia" ]; # use proprietary drivers

  hardware = {
    nvidia = {
      open = true; # recommended on turing+
      dynamicBoost.enable = true;
      powerManagement = {
        enable = true; # saves entire vram to /tmp/ instead of the bare minimum
        finegrained = true; # turns off gpu when not in use
      };
      prime = {
        intelBusId = "PCI:00:02:0";
        nvidiaBusId = "PCI:01:00:0";
        # prime offloading
        offload = {
          enable = true;
          enableOffloadCmd = true; # `nvidia-offload`
        };
      };
      nvidiaSettings = true;
    };
  };
}
