{
  config,
  lib,
  pkgs,
  ...
}:
let
  # TODO make sure this is not built for t480

  rootdir = "/mnt/storage/llama-cpp/";
  models = {

    gemma = {
      filename = "gemma-3-4b-it-GGUF_gemma-3-4b-it-Q8_0.gguf";
      flags =
        let
          mmproj = rootdir + "gemma-3-4b-it-GGUF_mmproj-model-f16.gguf";
          template = rootdir + "gemma3.jinja";
        in
        [
          "-c"
          "20000"
          "-fa"
          "-ngl"
          "999"
          "--mmproj"
          mmproj
          # "--jinja"
          # "--chat-template-file"
          # template
        ];
    };

    gpt = {
      small = {
        flags = [
          "-c" # context size, 0 for inherit
          "42000"
          "-fa" # flash attention
          "-ncmoe" # MoE blocks on cpu, -cmoe for +infty
          "12"
          "--n-gpu-layers" # layers on GPU
          "999"
          "--jinja"
          "--chat-template-kwargs"
          ''{"reasoning_effort": "high"}''
          "-np" # number of cache slots
          "2"
        ];
        filename = "gpt-oss-20b-GGUF_gpt-oss-20b-mxfp4.gguf";

      };
      big = {
        flags = [
          "-c"
          "0"
          "-fa"
          "-cmoe"
          "--n-gpu-layers"
          "999"
          "--jinja"
          "--chat-template-kwargs"
          ''{"reasoning_effort": "high"}''
          "-np"
          "10"
        ];
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
  environment.sessionVariables = {
    LLAMA_CACHE = "/mnt/storage/llama-cpp";
  };
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
