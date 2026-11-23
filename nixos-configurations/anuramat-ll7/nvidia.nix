{ inputs, pkgs, ... }:
{
  imports = [
    inputs.nixos-hardware.nixosModules.common-gpu-nvidia
  ];

  # fuser that sees every user's processes, for the fleet monitor's list of
  # the processes that have the dGPU open
  security.wrappers.fuser-all = {
    source = "${pkgs.psmisc}/bin/fuser";
    capabilities = "cap_dac_read_search,cap_sys_ptrace+ep";
    owner = "root";
    group = "wheel";
    permissions = "u+rx,g+x";
  };

  nixpkgs.config.cudaSupport = true;

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
