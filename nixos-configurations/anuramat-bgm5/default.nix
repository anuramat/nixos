{
  pkgs,
  inputs,
  ...
}:
{
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
    ./hardware-configuration.nix

    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-cpu-amd-pstate
    inputs.nixos-hardware.nixosModules.common-cpu-amd-zenpower
    inputs.nixos-hardware.nixosModules.common-gpu-amd
    inputs.nixos-hardware.nixosModules.common-pc-ssd

    inputs.nixos-hardware.nixosModules.common-hidpi
  ];

  # TODO zramSwap and tmpfs

  services.llama-cpp =
    let
      # TODO update ctx size and custom llama options
      models = {

        leanstral = {
          filename = "jackcloudman_Leanstral-2603-GGUF_mistralai_Leanstral-128x3.9B-2603-Q4_K_M.gguf";
          params = {
            # topP = 0.95;
            # topK = 20;
            # temp = 0.6;
            # minP = 0.00;
            #
            ctxSize = 1024;
            parallel = 1;
          };
        };
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
      enable = true;
      modelDir = "/mnt/storage/llama-cpp";
      package = pkgs.llama-cpp-vulkan;
      extraFlags = [
        "-dev"
        "Vulkan0"
      ];
      modelWrapped = models.leanstral;
    };
}
