{
  pkgs,
  inputs,
  ...
}:
{
  nix.distributedBuilds = false;
  system.stateVersion = "25.11";
  programs.captive-browser.interface = "wlp195s0";
  nixpkgs.config.rocmSupport = true;

  fileSystems."/mnt/storage" = {
    device = "/dev/disk/by-uuid/6f11006b-bc8c-40f2-be8c-419feb43654d";
    fsType = "ext4";
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = [
    "ttm.pages_limit=20971520" # VRAM GTT 80G
    # prophylactic against the DCN 3.5 IPS hang class:
    # flag bits: https://www.mail-archive.com/amd-gfx@lists.freedesktop.org/msg111203.html
    # same silicon: https://community.frame.work/t/amd-drivers-frequently-hanging-and-crashing/79270
    # https://wiki.archlinux.org/title/AMDGPU
    "amdgpu.dcdebugmask=0x600" # disable dynamic display IPS
  ];
  # hard-resets the machine if PID 1 is dead for 2m
  systemd.watchdog.runtimeTime = "2m";
  hardware.firmware = [
    pkgs.linux-firmware
    pkgs.strix-halo-mes-firmware # from nix-strix-halo tuning module
  ];

  imports = [
    inputs.self.nixosModules.default
    inputs.self.nixosModules.local
    inputs.self.nixosModules.builder
    ./hardware-configuration.nix
    ./llama.nix
    ./misc.nix
    ./power.nix
    ./rustdesk.nix

    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-cpu-amd-pstate
    inputs.nixos-hardware.nixosModules.common-cpu-amd-zenpower
    inputs.nixos-hardware.nixosModules.common-gpu-amd
    inputs.nixos-hardware.nixosModules.common-pc-ssd

    inputs.nixos-hardware.nixosModules.common-hidpi

    inputs.nix-strix-halo.nixosModules.ec-su-axb35
    inputs.nix-strix-halo.nixosModules.fastflowlm
    inputs.nix-strix-halo.nixosModules.ryzenadj
  ];

  nixpkgs.overlays = [
    (
      final: prev:
      let
        pkgs = inputs.nix-strix-halo.lib.mkPkgsOverlay {
          rocmTarget = inputs.nix-strix-halo.lib.therockTargets.defaultRocmTarget;
        } final prev;
      in
      {
        inherit (pkgs)
          ec-su-axb35
          ec-su-axb35-monitor
          strix-halo-mes-firmware
          ;
      }
    )
  ];

  # TODO tmpfs
  zramSwap.enable = true;

  environment.systemPackages = [
    pkgs.amd-debug-tools
  ];
}
