{
  pkgs,
  user,
  config,
  inputs,
  ezModules,
  ...
}:
{

  # topology.self = {
  #   hardware.info = ...;
  # };
  system.stateVersion = "24.05";
  home-manager.users.${user.username}.home.stateVersion = "24.11";

  programs.captive-browser.interface = "wlp0s20f3";

  # tis a big boy
  # TODO abstract away into a meta.nix variable
  nix.distributedBuilds = false;

  services = {
    keyd.keyboards.main.ids = [
      "048d:c997:193096a7"
    ];
  };

  imports = [
    ezModules.local
    ezModules.builder

    inputs.nixos-hardware.nixosModules.common-cpu-intel

    inputs.nixos-hardware.nixosModules.common-gpu-intel # they don't have this in the repo
    inputs.nixos-hardware.nixosModules.common-gpu-nvidia # compare to other modules

    inputs.nixos-hardware.nixosModules.common-hidpi
    inputs.nixos-hardware.nixosModules.common-pc-laptop
    inputs.nixos-hardware.nixosModules.common-pc-laptop-ssd

    ./hardware-configuration.nix
  ];

  # swapDevices = [
  #   {
  #     device = "/var/lib/swapfile";
  #     size = 64 * 1024;
  #   }
  # ];

  # vendor specifics {{{1
  environment.systemPackages = with pkgs; [
    lenovo-legion
  ];

  # TODO doesn't work for now, maybe reboot will help
  security.polkit.extraConfig = # javascript
    ''
      polkit.addRule((action, subject) => {
      	if (
      		subject.isInGroup("wheel") &&
      		["legion_cli", "legion_cli2", "legion_gui", "legion_gui2"].indexOf(
      			action.id,
      		) !== -1
      	) {
      		return polkit.Result.YES;
      	}
      });
    '';

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
        # TODO maybe these?
        # nvidia-vaapi-driver
        # libvdpau-va-gl
      ];
      enable32Bit = true; # compat
    };
  };
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
  # }}}
}
# vim: fdm=marker fdl=0
