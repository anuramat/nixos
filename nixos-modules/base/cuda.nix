{
  pkgs,
  lib,
  config,
  ...
}:
lib.mkIf (config.nixpkgs.config.cudaSupport or false) {
  hardware.nvidia-container-toolkit = {
    enable = config.hardware.nvidia.enabled;
    mount-nvidia-executables = true;
  };
  programs.nix-ld.libraries = [
    config.hardware.nvidia.package
    pkgs.cudaPackages.cudatoolkit
  ];
}
