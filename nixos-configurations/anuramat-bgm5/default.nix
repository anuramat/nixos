{
  pkgs,
  inputs,
  ...
}:
{
  services.llama-cpp =
    let
      models = {
        big = {
          modelFile = "unsloth_Qwen3.5-122B-A10B-GGUF_Q4_K_M_Qwen3.5-122B-A10B-Q4_K_M-00001-of-00003.gguf";
          modelExtra = {
            id = "qwen3.5-122b";
            params = {
              topP = 0.95;
              topK = 20;
              temp = 0.6;
              minP = 0.00;

              ctxSize = 30000;
              parallel = 5;
            };
          };
        };
      };
      selected = models.big;
    in
    {
      enable = true;
      modelDir = "/mnt/storage/llama-cpp";
      package = pkgs.llama-cpp-vulkan;
      extraFlags = [
        "-dev"
        "Vulkan0"
      ];
      inherit (selected) modelFile modelExtra;
    };
  nix.distributedBuilds = false;
  system.stateVersion = "25.11";
  home-manager.users.anuramat.home.stateVersion = "25.11";
  networking.hostName = "anuramat-bgm5";

  hardware.amdgpu.opencl.enable = true;
  services.ollama.acceleration = "vulkan";

  nixpkgs.config.rocmSupport = true;

  fileSystems."/mnt/storage" = {
    device = "/dev/disk/by-uuid/6f11006b-bc8c-40f2-be8c-419feb43654d";
    fsType = "ext4";
  };

  hardware.firmware = [ pkgs.linux-firmware ];

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

  boot.kernelPackages = pkgs.linuxPackages_latest;

  environment.systemPackages = with pkgs; [
    rocmPackages.rocm-smi
  ];

  programs.captive-browser.interface = "wlp195s0";
}
