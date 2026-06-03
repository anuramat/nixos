{
  pkgs,
  inputs,
  ...
}:
let
  llamaPkg = pkgs.llama-cpp-vulkan;
  immichPort = 2283;
in
{

  home-manager.users.anuramat = {
    programs.niri.settings.input.touchpad.tap = true;
  };

  services.immich = {
    enable = true;
    host = "0.0.0.0";
    port = immichPort;
  };

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
    immichPort
  ];

  nix.distributedBuilds = false;
  nixpkgs.config.rocmSupport = true;

  system.stateVersion = "25.11";
  home-manager.users.anuramat.home.stateVersion = "25.11";
  networking.hostName = "anuramat-bgm5";
  programs.captive-browser.interface = "wlp195s0";

  fileSystems."/mnt/storage" = {
    device = "/dev/disk/by-uuid/6f11006b-bc8c-40f2-be8c-419feb43654d";
    fsType = "ext4";
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;
  hardware.firmware = [ pkgs.linux-firmware ];

  imports = [
    inputs.self.nixosModules.default
    inputs.self.nixosModules.local
    inputs.self.nixosModules.anuramat
    inputs.self.nixosModules.builder
    ./hardware-configuration.nix

    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-cpu-amd-pstate
    inputs.nixos-hardware.nixosModules.common-cpu-amd-zenpower
    inputs.nixos-hardware.nixosModules.common-gpu-amd
    inputs.nixos-hardware.nixosModules.common-pc-ssd

    inputs.nixos-hardware.nixosModules.common-hidpi

    inputs.nix-strix-halo.nixosModules.ec-su-axb35
    inputs.nix-strix-halo.nixosModules.tuning
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

  services = {
    ryzenadj = {
      enable = true;
    };
    ec-su-axb35 = {
      enable = true;
      monitor.enable = true;
      # powerMode = "balanced";
    };
  };

  # TODO zramSwap and tmpfs

  services.llama-cpp =
    let
      # TODO update ctx size and custom llama options
      models = {
        qwen35 = {
          filename = "unsloth_Qwen3.5-35B-A3B-GGUF_Qwen3.5-35B-A3B-UD-Q4_K_XL.gguf";
          params = {
            topP = 0.95;
            topK = 20;
            temp = 0.6;
            minP = 0.00;

            ctxSize = 262144;
            parallel = 5;
          };
        };
        oss120 = {
          filename = "ggml-org_gpt-oss-120b-GGUF_gpt-oss-120b-mxfp4-00001-of-00003.gguf";
          params = {
            topP = 1.0;
            topK = 0;
            temp = 1.0;
            minP = 0.00;
            ctxSize = 131072;
            parallel = 3;
          };
        };
      };
    in
    {
      enable = false;
      modelDir = "/mnt/storage/llama-cpp";
      package = llamaPkg;
      extraFlags = [
        "-dev"
        "Vulkan0"
      ];
      modelWrapped = models.qwen35;
    };

  environment = {
    systemPackages = [
      llamaPkg
      pkgs.amd-debug-tools
    ];
  };
}
