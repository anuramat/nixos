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

    gemma = {
      # TODO replace
      filename = "gemma-3-4b-it-GGUF_gemma-3-4b-it-Q8_0.gguf";
      flags =
        let
          mmproj = rootdir + "gemma-3-4b-it-GGUF_mmproj-model-f16.gguf";
          template = rootdir + "gemma3.jinja";
        in
        [
          "-c"
          "20000"
          "--mmproj"
          mmproj
          # "--jinja"
          # "--chat-template-file"
          # template
        ];
    };

    qwen =
      let
        flags = [
          "--jinja"

          "--temp"
          "0.7"
          "--min-p"
          "0.0"
          "--top-p"
          "0.80"
          "--top-k"
          "20"
          "--repeat-penalty"
          "1.05"

          "-ncmoe"
          "38"
          "-c"
          "30000"
        ];
      in
      {
        # TODO add reasoner
        # TODO rewrite with a map to not repeat inherit flags
        coder = {
          filename = "unsloth_Qwen3-Coder-30B-A3B-Instruct-GGUF_Qwen3-Coder-30B-A3B-Instruct-Q4_K_M.gguf";
          inherit flags;
        };

        instruct = {
          filename = "unsloth_Qwen3-30B-A3B-Instruct-2507-GGUF_Qwen3-30B-A3B-Instruct-2507-Q4_K_M.gguf";
          inherit flags;
        };
        reasoning = {
          filename = "";
          inherit flags;
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
        small = {
          flags = [
            "-c" # context size, 0 for inherit
            "55000"
            "-ncmoe" # MoE blocks on cpu, -cmoe for +infty
            "12"
            "-np" # number of cache slots
            "2"
          ]
          ++ common;
          filename = "unsloth_gpt-oss-20b-GGUF_gpt-oss-20b-Q4_K_M.gguf";

        };
        big = {
          flags = [
            "-c"
            "0"
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
    # should be in ll7 module
    LLAMA_CACHE = "/mnt/storage/llama-cpp";
  };
  services = {
    llama-cpp =
      let
        modelAttrs = models.qwen;
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
