{
  config,
  lib,
  unstable,
  ...
}:
let
  # nvidia = config.hardware.nvidia.enabled; # only in unstable
  nvidia = lib.elem "nvidia" config.services.xserver.videoDrivers;
  inherit (lib) mkIf;
in
{
  services.ollama = {
    package = unstable.ollama;
    enable = true;
    acceleration = mkIf nvidia "cuda";
    # pull models on service start
    loadModels = [ ];
  };
}
