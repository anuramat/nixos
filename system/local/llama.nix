{
  config,
  lib,
  pkgs,
  ...
}:
{

  environment.systemPackages = [
    pkgs.llama-cpp
  ];
  services =
    let
      cuda = config.hardware.nvidia.enabled;
    in
    {
      llama-cpp = {
        enable = true;
        port = 11343;
        openFirewall = false;
      };
      ollama = {
        enable = true;
        acceleration = lib.mkIf cuda "cuda";
        loadModels = lib.mkIf cuda [ ]; # pull models on service start
        models = "/mnt/storage/models"; # TODO abstract away; make a new variable that contains a path to a storage device; fill on different machines
        environmentVariables = {
          OLLAMA_FLASH_ATTENTION = "1";
          OLLAMA_KEEP_ALIVE = "999999m";
          # OLLAMA_CONTEXT_LENGTH = "200000";
        };
        port = 11434; # explicit default
        host = "0.0.0.0";
        openFirewall = false;
      };
    };
}
