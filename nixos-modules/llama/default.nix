{
  pkgs,
  ...
}:
let
  port = 11343;
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
    qwen = {
      model = modelDir + "/unsloth_Qwen3-Coder-Next-GGUF_Qwen3-Coder-Next-UD-Q4_K_XL.gguf";
      modelExtra = {
        id = "qwen3-coder-next";
        params = {
          topP = 0.95;
          topK = 40;
          temp = 1.0;

          ctxSize = 30000;
          parallel = 1;
        };
      };
    };
  };

  package = pkgs.llama-cpp-vulkan;
in

{
  imports = [ ./options.nix ];
  environment.systemPackages = [
    package
  ];
  environment.sessionVariables = {
    LLAMA_CACHE = modelDir;
  };
  services = {
    llama-cpp =
      let
        selected = models.glm;
      in
      {
        enable = true;
        inherit package;
        openFirewall = false;
        host = "0.0.0.0";
        inherit port;
        inherit (selected) model modelExtra;
      };
  };
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
    port
  ];
}
