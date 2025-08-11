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
        enable = true;
        port = 11343;
        openFirewall = false;
        extraFlags = [
          "-c" # context size
          "0" # inherit
          "-fa" # flash attention
          "-cmoe" # all MoE blocks on CPU
          "--n-gpu-layers" # how many layers on GPU
          "999"
          # some hacks that don't even work for now; fix later
          "--jinja"
          "--reasoning-format"
          "none"
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
