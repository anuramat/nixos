# TODO add id and name fields to models
{
  config,
  lib,
  pkgs,
  ...
}:
let
  # TODO make sure this is not built for t480

  rootdir = "/mnt/storage/llama-cpp/"; # put in sessionvar TODO
  models = {

    gemma = rec {
      # TODO replace
      filename = "gemma-3-4b-it-GGUF_gemma-3-4b-it-Q8_0.gguf";
      flags =
        let
          mmproj = rootdir + "gemma-3-4b-it-GGUF_mmproj-model-f16.gguf";
          template = rootdir + "gemma3.jinja";
        in
        [
          "-c"
          (toString context)
          "--mmproj"
          mmproj
          # "--jinja"
          # "--chat-template-file"
          # template
        ];
      context = 20000;
    };

    qwen =
      let
        mk =
          {
            filename,
            thinking ? false,
            size ? "small",
          }:
          let
            context = if size == "small" then 30000 else 0;
          in
          {
            inherit filename context;
            flags =
              let
                flagsInstruct = [
                  "--temp"
                  "0.7"
                  "--min-p"
                  "0.0" # or 0.01
                  "--top-p"
                  "0.80"
                ];
                flagsThinking = [
                  "--temp"
                  "0.6"
                  "--min-p"
                  "0.0"
                  "--top-p"
                  "0.95"
                ];
                flagsBig = [
                  "-ncmoe"
                  "38"
                ];
                flagsSmall = [ ];
              in
              [
                "--top-k"
                "20"
                "--jinja"
                "-c"
                (toString context)
              ]
              ++ (if thinking then flagsThinking else flagsInstruct)
              ++ (
                if size == "small" then
                  [ ]
                else if size == "big" then
                  flagsBig
                else
                  throw "invalid size"
              );
          };
      in
      {
        small = {
          instruct = mk {
            filename = "unsloth_Qwen3-4B-Instruct-2507-GGUF_Qwen3-4B-Instruct-2507-Q4_K_M.gguf";
            thinking = false;
            size = "small";
          };
          thinking = mk {
            filename = "unsloth_Qwen3-4B-Thinking-2507-GGUF_Qwen3-4B-Thinking-2507-Q4_K_M.gguf";
            thinking = true;
            size = "small";
          };
        };
        big = {
          coder = mk {
            filename = "unsloth_Qwen3-Coder-30B-A3B-Instruct-GGUF_Qwen3-Coder-30B-A3B-Instruct-Q4_K_M.gguf";
            thinking = false;
            size = "big";
          };
          instruct = mk {
            filename = "unsloth_Qwen3-30B-A3B-Instruct-2507-GGUF_Qwen3-30B-A3B-Instruct-2507-Q4_K_M.gguf";
            thinking = false;
            size = "big";
          };
          thinking = mk {
            filename = "unsloth_Qwen3-30B-A3B-Thinking-2507-GGUF_Qwen3-30B-A3B-Thinking-2507-Q4_K_M.gguf";
            thinking = true;
            size = "big";
          };
        };
      };

    gpt =
      let
        common = [
          "--top-p"
          "1.0"
          "--top-k"
          "0"
          "--temp"
          "1.0"
          "--jinja"
          "--chat-template-kwargs"
          ''{"reasoning_effort": "high"}''
        ];
      in
      {
        small = rec {
          context = 55000;
          flags = [
            "-c" # context size, 0 for inherit
            (toString context)
            "-ncmoe" # MoE blocks on cpu, -cmoe for +infty
            "12"
            "-np" # number of cache slots
            "4"
          ]
          ++ common;
          filename = "unsloth_gpt-oss-20b-GGUF_gpt-oss-20b-Q4_K_M.gguf";

        };
        big = rec {
          context = 131072;
          flags = [
            "-c"
            (toString context)
            "-cmoe"
            "-np"
            "10"
          ];
          filename = "ggml-org_gpt-oss-120b-GGUF_gpt-oss-120b-mxfp4-00001-of-00003.gguf";
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
    # TODO should be reworked
    LLAMA_CACHE = "/mnt/storage/llama-cpp";
  };
  services = {
    llama-cpp =
      let
        modelAttrs = models.qwen.small.thinking;
      in
      {
        enable = true;
        port = 11343;
        openFirewall = false;
        extraFlags = modelAttrs.flags ++ [
          "-fa"
          "-ngl"
          "999"
        ];
        model = rootdir + modelAttrs.filename;
      };
  };
}
