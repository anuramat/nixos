{ lib, config, ... }:
lib.mkIf (config.nixpkgs.config.cudaSupport or false) {
  hardware.nvidia-container-toolkit = {
    enable = config.hardware.nvidia.enabled;
    mount-nvidia-executables = true;
  };
}
