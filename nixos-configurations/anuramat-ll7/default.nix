{
  pkgs,
  config,
  inputs,
  ...
}:
{
  system.stateVersion = "24.05";
  home-manager.users.anuramat.home.stateVersion = "24.11";
  networking.hostName = "anuramat-ll7";
  nix.distributedBuilds = false;

  programs.captive-browser.interface = "wlp0s20f3";
  services = {
    keyd.keyboards.main.ids = [
      "048d:c997:193096a7"
    ];
  };
  environment.sessionVariables.WLR_DRM_DEVICES = "/dev/dri/by-path/pci-0000:00:02.0-card"; # used by sway startup script to start on iGPU

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
    # inputs.self.nixosModules.llama # TODO re-enable?

    inputs.nixos-hardware.nixosModules.common-cpu-intel

    inputs.nixos-hardware.nixosModules.common-gpu-intel # they don't have this in the repo

    inputs.nixos-hardware.nixosModules.common-hidpi
    inputs.nixos-hardware.nixosModules.common-pc-laptop
    inputs.nixos-hardware.nixosModules.common-pc-laptop-ssd

    ./hardware-configuration.nix
  ];

  boot = {
    tmp.useTmpfs = true; # NOTE might want to enable swap later
    extraModulePackages = [
      config.boot.kernelPackages.lenovo-legion-module
    ];
  };

  # GPU {{{1
  nixpkgs.config.cudaSupport = true;
  hardware = {
    graphics = {
      extraPackages = with pkgs; [
        # vaapiVdpau # no fucking idea what this does TODO
        # TODO just removed this on 2025-10-11, should work fine without it
      ];
      enable32Bit = true; # compat
    };
  };

}
# vim: fdm=marker fdl=0
