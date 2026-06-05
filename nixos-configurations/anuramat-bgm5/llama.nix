{ pkgs, ... }:
let
  llamaPkg = pkgs.llama-cpp-vulkan;
  models = {
    qwen35 = {
      filename = "unsloth_Qwen3.5-35B-A3B-GGUF_Qwen3.5-35B-A3B-UD-Q4_K_XL.gguf";
      params = {
        topP = 0.95;
        topK = 20;
        temp = 0.6;
        minP = 0.00;

        ctxSize = 262144;
        parallel = 5;
      };
    };
    oss120 = {
      filename = "ggml-org_gpt-oss-120b-GGUF_gpt-oss-120b-mxfp4-00001-of-00003.gguf";
      params = {
        topP = 1.0;
        topK = 0;
        temp = 1.0;
        minP = 0.00;
        ctxSize = 131072;
        parallel = 3;
      };
    };
  };
in
{
  services.llama-cpp = {
    enable = false;
    modelDir = "/mnt/storage/llama-cpp";
    package = llamaPkg;
    extraFlags = [
      "-dev"
      "Vulkan0"
    ];
    modelWrapped = models.qwen35;
  };

  environment = {
    systemPackages = [
      llamaPkg
    ];
  };
}
