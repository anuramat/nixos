{
  pkgs,
  ...
}:
let
  modelDir = "/mnt/storage/llama-cpp";

  models = {
    glm = {
      model = modelDir + "/unsloth_GLM-4.7-Flash-GGUF_GLM-4.7-Flash-Q4_K_M.gguf";
      modelExtra = {
        id = "glm-4.7-flash";
        params = {
          topP = 1.0;
          topK = 0;
          temp = 1.0;

          ctxSize = 30000;
          parallel = 1;
        };
      };
    };

    gemma = {
      model = modelDir + "/gemma-3-4b-it-GGUF_gemma-3-4b-it-Q8_0.gguf";
      modelExtra = {
        id = "gemma3:4b-it";
        vision = true;
        params = {
          mmprojFile = modelDir + "/gemma-3-4b-it-GGUF_mmproj-model-f16.gguf";
          ctxSize = 20000;
          jinja = false;
          # chatTemplateFile = modelDir + "/gemma3.jinja";
        };
      };
    };

    qwen =
      let
        mk =
          {
            filename,
            type,
            size,
          }:
          {
            model = modelDir + "/" + filename;
            modelExtra = {
              id = "qwen3-${type}:${size}";
              thinking = type == "thinking";
              params = {
                ctxSize =
                  {
                    "4b" = 30000;
                    "30b" = 35000;
                  }
                  .${size};
                topK = 20;
                temp = if type == "thinking" then 0.6 else 0.7;
                minP = 0.0; # for instruct/coder models 0.01 also works
                topP = if type == "thinking" then 0.95 else 0.80;
              };
            };
          };
      in
      {
        instruct4b = mk {
          filename = "unsloth_Qwen3-4B-Instruct-2507-GGUF_Qwen3-4B-Instruct-2507-Q4_K_M.gguf";
          type = "instruct";
          size = "4b";
        };
        thinking4b = mk {
          filename = "unsloth_Qwen3-4B-Thinking-2507-GGUF_Qwen3-4B-Thinking-2507-Q4_K_M.gguf";
          type = "thinking";
          size = "4b";
        };

        instruct30b = mk {
          filename = "unsloth_Qwen3-30B-A3B-Instruct-2507-GGUF_Qwen3-30B-A3B-Instruct-2507-Q4_K_M.gguf";
          type = "instruct";
          size = "30b";
        };
        thinking30b = mk {
          filename = "unsloth_Qwen3-30B-A3B-Thinking-2507-GGUF_Qwen3-30B-A3B-Thinking-2507-Q4_K_M.gguf";
          type = "thinking";
          size = "30b";
        };

        coder = mk {
          filename = "unsloth_Qwen3-Coder-30B-A3B-Instruct-GGUF_Qwen3-Coder-30B-A3B-Instruct-Q4_K_M.gguf";
          type = "coder";
          size = "30b";
        };
      };

    gpt =
      let
        commonParams = {
          topP = 1.0;
          topK = 0;
          temp = 1.0;
          chatTemplateKwargs = {
            reasoning_effort = "high";
          };
        };
      in
      {
        small = {
          model = modelDir + "/unsloth_gpt-oss-20b-GGUF_gpt-oss-20b-Q4_K_M.gguf";
          modelExtra = {
            id = "gpt-oss:20b";
            params = commonParams // {
              ctxSize = 55000;
              parallel = 4;
            };
          };
        };
        big = {
          model = modelDir + "/ggml-org_gpt-oss-120b-GGUF_gpt-oss-120b-mxfp4-00001-of-00003.gguf";
          modelExtra = {
            id = "gpt-oss:120b";
            params = commonParams // {
              ctxSize = 131072;
              parallel = 10;
            };
          };
        };
      };
  };

  port = 11343;
in

{
  imports = [ ./options.nix ];
  environment.systemPackages = [
    pkgs.llama-cpp
  ];
  environment.sessionVariables = {
    LLAMA_CACHE = modelDir;
  };
  services = {
    llama-cpp =
      let
        # selected = models.qwen.thinking4b;
        selected = models.glm;
      in
      {
        enable = true;
        openFirewall = false;
        inherit port;
        inherit (selected) model modelExtra;
      };
  };
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
    port
  ];
}
