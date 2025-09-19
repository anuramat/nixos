{
  pkgs,
  config,
  inputs,
  hax,
  ...
}:
{

  # topology.self = {
  #   hardware.info = ...;
  # };
  system.stateVersion = "24.05";
  home-manager.users.anuramat.home.stateVersion = "24.11";
  networking.hostName = "anuramat-ll7";

  programs.captive-browser.interface = "wlp0s20f3";

  # tis a big boy
  # TODO abstract away into a meta.nix variable
  nix.distributedBuilds = false;

  services = {
    keyd.keyboards.main.ids = [
      "048d:c997:193096a7"
    ];
  };

  # specialisation.vfio.configuration = {
  #   imports = [
  #   ];
  # };

  imports = [
    # ./nvidia-vm.nix
    ./nvidia-host.nix
    inputs.self.nixosModules.default
    inputs.self.nixosModules.local
    inputs.self.nixosModules.builder
    inputs.self.nixosModules.anuramat
    inputs.self.nixosModules.llama

    inputs.nixos-hardware.nixosModules.common-cpu-intel

    inputs.nixos-hardware.nixosModules.common-gpu-intel # they don't have this in the repo

    inputs.nixos-hardware.nixosModules.common-hidpi
    inputs.nixos-hardware.nixosModules.common-pc-laptop
    inputs.nixos-hardware.nixosModules.common-pc-laptop-ssd

    ./hardware-configuration.nix
  ];

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
  environment.sessionVariables.WLR_DRM_DEVICES = "/dev/dri/by-path/pci-0000:00:02.0-card"; # used by sway startup script to start on iGPU
}
# vim: fdm=marker fdl=0
