{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.services.llama-cpp;
  llamaPkg = pkgs.llama-cpp-vulkan;
  modelDir = "/mnt/storage/llama-cpp";
  inherit (inputs.self.llama) port;

  models = {
    qwen35 = {
      filename = "unsloth_Qwen3.5-35B-A3B-GGUF_Qwen3.5-35B-A3B-UD-Q4_K_XL.gguf";
      flags = [
        "--min-p"
        "0"
        "--temp"
        "0.6"
        "--top-k"
        "20"
        "--top-p"
        "0.95"
        "-c"
        "262144"
        "-np"
        "5"
      ];
    };
    oss120 = {
      filename = "ggml-org_gpt-oss-120b-GGUF_gpt-oss-120b-mxfp4-00001-of-00003.gguf";
      flags = [
        "--min-p"
        "0"
        "--temp"
        "1.0"
        "--top-k"
        "0"
        "--top-p"
        "1.0"
        "-c"
        "131072"
        "-np"
        "3"
      ];
    };
  };
  selected = models.qwen35;
in
{
  services.llama-cpp = {
    inherit port;
    enable = false;
    package = llamaPkg;
    openFirewall = false;
    host = "0.0.0.0";
    model = "${modelDir}/${selected.filename}";
    extraFlags = selected.flags ++ [
      "-dev"
      "Vulkan0"
    ];
  };

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = lib.optionals cfg.enable [ port ];

  environment = {
    sessionVariables.LLAMA_CACHE = modelDir;
    systemPackages = [ llamaPkg ];
  };
}
