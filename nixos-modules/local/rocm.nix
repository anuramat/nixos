{
  pkgs,
  lib,
  config,
  ...
}:
lib.mkIf (config.nixpkgs.config.rocmSupport or false) {
  environment.systemPackages = with pkgs; [
    rocmPackages.rocm-smi
    libdrm
    amdgpu_top
  ];

  hardware.amdgpu.opencl.enable = true;
  services.ollama.package = pkgs.ollama-rocm;
}
