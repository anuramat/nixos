{
  pkgs,
  inputs,
  ...
}:
{
  nix.distributedBuilds = false;
  system.stateVersion = "25.11";
  home-manager.users.anuramat.home.stateVersion = "25.11";
  networking.hostName = "anuramat-bgm5";

  nixpkgs.config.rocmSupport = true;

  fileSystems."/mnt/storage" = {
    device = "/dev/disk/by-uuid/6f11006b-bc8c-40f2-be8c-419feb43654d";
    fsType = "ext4";
  };

  imports = [
    inputs.self.nixosModules.default
    inputs.self.nixosModules.local
    inputs.self.nixosModules.anuramat
    ./hardware-configuration.nix

    # originally for framework desktop
    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-cpu-amd-pstate
    inputs.nixos-hardware.nixosModules.common-gpu-amd
    inputs.nixos-hardware.nixosModules.common-pc-ssd

    inputs.nixos-hardware.nixosModules.common-hidpi

    inputs.self.nixosModules.llama
  ];
  # TODO zramSwap and tmpfs
  # TODO drop laptop specific stuff: tlp, thermald

  # recommended in nixos-hardware readme for framework desktop
  boot.kernelPackages = pkgs.linuxPackages_6_18;

  environment.systemPackages = with pkgs; [
    rocmPackages.rocm-smi
  ];

  programs.captive-browser.interface = "wlp195s0";
}
