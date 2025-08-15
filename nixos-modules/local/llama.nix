{
  config,
  lib,
  pkgs,
  ...
}:
let
  rootdir = "/mnt/storage/llama-cpp/";
  models = {

    gemma = {
      filename = "gemma-3-4b-it-GGUF_gemma-3-4b-it-Q8_0.gguf";
      flags =
        let
          mmproj = rootdir + "gemma-3-4b-it-GGUF_mmproj-model-f16.gguf";
        in
        [
          "-c"
          "20000"
          "-fa"
          "-ngl"
          "999"
          "--mmproj"
          mmproj
        ];
    };

    gpt =
      let
        effort = "high";
        flags = [
          "-c" # context size
          "0" # inherit
          "-fa" # flash attention
          "-cmoe" # all MoE blocks on CPU
          "--n-gpu-layers" # how many layers on GPU
          "999"
          "--jinja"
          "--chat-template-kwargs"
          ''{"reasoning_effort": "${effort}"}''
        ];

      in

      {
        small = {
          inherit flags;
          filename = "gpt-oss-20b-GGUF_gpt-oss-20b-mxfp4.gguf";

        };
        big = {
          inherit flags;
          filename = "gpt-oss-120b-mxfp4-00001-of-00003.gguf";
        };
      };
  };

in

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
      llama-cpp =
        let
          modelAttrs = models.gpt.small;
        in
        {
          enable = true;
          port = 11343;
          openFirewall = false;
          extraFlags = modelAttrs.flags;
          model = rootdir + modelAttrs.filename;

        };
      ollama = {
        enable = false;
        acceleration = lib.mkIf cuda "cuda";
        loadModels = lib.mkIf cuda [ ]; # pull models on service start
        models = "/mnt/storage/ollama"; # TODO abstract away; make a new variable that contains a path to a storage device; fill on different machines
        environmentVariables = {
          OLLAMA_FLASH_ATTENTION = "1";
          OLLAMA_KEEP_ALIVE = "5m";
          # OLLAMA_CONTEXT_LENGTH = "200000";
        };
        port = 11434; # explicit default
        host = "127.0.0.1";
        openFirewall = false;
      };
    };
}
