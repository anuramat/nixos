{
  pkgs,
  config,
  inputs,
  ...
}:
{
  system.stateVersion = "24.05";
  home-manager.users.${config.user}.home.stateVersion = "24.11";
  nix.distributedBuilds = false;
  services = {
    keyd.keyboards.main.ids = [
      "048d:c997:193096a7"
    ];
    # ssd
    fstrim.enable = true;
    # proprietary drivers TODO huh
    xserver = {
      dpi = 236;
    };
    tlp.settings = {
      # turn on battery charge threshold
      # `tlp fullcharge` to charge to 100% once
      # values taken from <https://linrunner.de/tlp/faq/battery.html>
      START_CHARGE_THRESH_BAT0 = 40;
      STOP_CHARGE_THRESH_BAT0 = 50;
      CPU_MAX_PERF_ON_BAT = 20;
    };
  };

  # TODO too much to recompile
  # nixpkgs.config.cudaSupport = true;

  imports = [
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-gpu-intel
    ./hardware-configuration.nix
  ];

  environment.systemPackages = with pkgs; [
    lenovo-legion
  ];

  boot = {
    extraModulePackages = [
      config.boot.kernelPackages.lenovo-legion-module
    ];
  };

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 128 * 1024;
    }
  ];

  # nvidia TODO tidy
  # {{{1
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware = {
    nvidia = {
      open = true; # recommended on turing+
      modesetting.enable = true; # wiki says this is required
      # these two are experimental
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
    graphics = {
      extraPackages = with pkgs; [
        vaapiVdpau # no fucking idea what this does
      ];
      # no idea what these do anymore
      enable = true;
      enable32Bit = true;
    };
  };
  # }}}
}
# vim: fdm=marker fdl=0
