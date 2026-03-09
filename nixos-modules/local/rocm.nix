{ lib, config, ... }:
lib.mkIf (config.nixpkgs.config.rocmSupport or false) {
  environment.systemPackages = with pkgs; [
    rocmPackages.rocm-smi
    libdrm
    nvtopPackages.amd
  ];
}
