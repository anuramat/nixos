{
  config,
  lib,
  pkgs,
  ...
}:
{

  environment.systemPackages = [
    pkgs.llama-cpp
    pkgs.python313Packages.huggingface-hub
  ];
  services =
    let
      cuda = config.hardware.nvidia.enabled;
    in
    {
      llama-cpp = {
        enable = enable;
        port = 11434;
        openFirewall = false;
        extraFlags = [
          "-c"
          "0"
          "-fa"
          "--jinja"
          "--reasoning-format"
          "none"
          "-cmoe"
          "--n-gpu-layers"
          "999"
        ];
        model = "/mnt/storage/llama-cpp/gpt-oss-120b-mxfp4-00001-of-00003.gguf";
        # model = "/mnt/storage/llama-cpp/gpt-oss-20b-GGUF_gpt-oss-20b-mxfp4.gguf";
      };
      ollama = {
        enable = false;
        acceleration = lib.mkIf cuda "cuda";
        loadModels = lib.mkIf cuda [ ]; # pull models on service start
        models = "/mnt/storage/ollama"; # TODO abstract away; make a new variable that contains a path to a storage device; fill on different machines
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
