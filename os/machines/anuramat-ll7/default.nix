{
  pkgs,
  user,
  config,
  inputs,
  ...
}:
{
  system.stateVersion = "24.05";
  home-manager.users.${user.username}.home.stateVersion = "24.11";

  programs.captive-browser.interface = "wlp0s20f3";

  # tis a big boy
  nix.distributedBuilds = false;

  services = {
    keyd.keyboards.main.ids = [
      "048d:c997:193096a7"
    ];
    # proprietary drivers TODO huh
    xserver = {
      # dpi = 236; # TODO test if we need this
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

  imports = [
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-gpu-intel
    ./hardware-configuration.nix
  ];

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 64 * 1024;
    }
  ];

  # vendor specifics {{{1
  environment.systemPackages = with pkgs; [
    lenovo-legion
  ];

  boot = {
    extraModulePackages = [
      config.boot.kernelPackages.lenovo-legion-module
    ];
  };

  # GPU {{{1
  nixpkgs.config.cudaSupport = true;
  hardware = {
    graphics = {
      extraPackages = with pkgs; [
        vaapiVdpau # no fucking idea what this does TODO
      ];
      enable32Bit = true; # compat
    };
  };
  services.xserver.videoDrivers = [ "nvidia" ]; # use proprietary drivers
  hardware = {
    nvidia = {
      open = true; # recommended on turing+
      # dynamicBoost.enable = true; # TODO think about it
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
  # }}}
}
# vim: fdm=marker fdl=0
