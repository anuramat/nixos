{
  lib,
  pkgs,
  inputs,
  ...
}:
{
  system.stateVersion = "25.11";
  programs.captive-browser.interface = "wlp195s0";

  home-manager.users.${inputs.self.consts.user.username}.programs.noctalia.settings.lockscreen_widgets.widget.login.output =
    "DP-3";
  nixpkgs.config.rocmSupport = true;

  fileSystems."/mnt/storage" = {
    device = "/dev/disk/by-uuid/6f11006b-bc8c-40f2-be8c-419feb43654d";
    fsType = "ext4";
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      "ttm.pages_limit=20971520" # VRAM GTT 80G
      # prophylactic against the DCN 3.5 IPS hang class:
      # flag bits: https://www.mail-archive.com/amd-gfx@lists.freedesktop.org/msg111203.html
      # same silicon: https://community.frame.work/t/amd-drivers-frequently-hanging-and-crashing/79270
      # https://wiki.archlinux.org/title/AMDGPU
      "amdgpu.dcdebugmask=0x600" # disable dynamic display IPS
    ];
    # panic on a hard lockup and reboot 10s later, instead of staying frozen;
    # the panic log goes to EFI pstore, systemd-pstore saves it on the next boot
    kernel.sysctl = {
      "kernel.hardlockup_panic" = 1;
      "kernel.panic" = 10;
    };
  };
  # hard-resets the machine if PID 1 is dead for 2m
  systemd.settings.Manager.RuntimeWatchdogSec = "2m";
  # corefreqk reads SMN registers from interrupt context on every thread, every
  # second; one such read stalled and hard-locked the machine; upstream says to
  # run no other SMU driver alongside it, and ryzenadj needs ryzen_smu
  programs.corefreq.enable = lib.mkForce false;
  hardware.firmware = [
    pkgs.strix-halo-mes-firmware # from nix-strix-halo tuning module
  ];

  imports = [
    inputs.self.nixosModules.base
    ./hardware-configuration.nix
    ./decision-bot.nix
    ./llama.nix
    ./maintenance.nix
    ./misc.nix
    ./power.nix

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
          ec-su-axb35-monitor
          strix-halo-mes-firmware
          ;
        # NOTE upstream builds the module with pkgs.stdenv instead of
        # kernel.stdenv, which breaks once the kernel's compiler differs (e.g.
        # GCC 16 kernel from unstable-slow); drop when fixed upstream
        ec-su-axb35 =
          { kernel }:
          (prev.callPackage "${inputs.nix-strix-halo}/pkgs/ec-su-axb35.nix" {
            pkgs = final // {
              inherit (kernel) stdenv;
            };
            ec-su-axb35-src = inputs.nix-strix-halo.inputs.ec-su-axb35;
          }).kernelModule
            { inherit kernel; };
      }
    )
  ];

  # TODO tmpfs
  zramSwap.enable = true;

  environment.systemPackages = [
    pkgs.amd-debug-tools
  ];
}
