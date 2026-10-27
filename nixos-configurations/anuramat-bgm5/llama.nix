{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.services.llama-cpp;
  # the server runs on Vulkan0: skip the HIP backend that config.rocmSupport adds (built for
  # every GPU arch), the per-ISA CPU backends, and the tests, which only cover the CPU
  llamaPkg =
    (pkgs.llama-cpp.override {
      vulkanSupport = true;
      rocmSupport = false;
      cpuArchDynamicDispatch = false;
    }).overrideAttrs
      { doCheck = false; };
  modelDir = "/mnt/storage/llama-cpp";
  inherit (inputs.self.consts.llama) port;

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
    # decision models, served on /v1/systemone
    knowline = {
      filename = "KnowLine-35B-A3B-Gen1.Q8_0.gguf";
      flags = [
        "-fa"
        "on"
        "-c"
        "32768"
        "-np"
        "4"
        "-b"
        "4096"
        "-ub"
        "4096"
      ];
      # a plain causal LM: knowline.py answers /v1/systemone from llama-server's label-token logprobs
      frontend = true;
    };
    d3 = {
      filename = "vllm-d3-Q8_0.gguf";
      # the whole prompt, images included, has to fit in one ubatch
      flags = [
        "--mmproj"
        "${modelDir}/mmproj-vllm-d3-Q8_0.gguf"
        "-fa"
        "on"
        "-c"
        "8192"
        "-b"
        "8192"
        "-ub"
        "8192"
      ];
    };
  };
  selected = models.knowline;
  frontend = selected.frontend or false;
  # with a front end, llama-server listens locally behind it
  llamaPort = if frontend then port + 1 else port;
in
{
  services.llama-cpp = {
    port = llamaPort;
    enable = false;
    package = llamaPkg;
    openFirewall = false;
    host = if frontend then "127.0.0.1" else "0.0.0.0";
    model = "${modelDir}/${selected.filename}";
    extraFlags = selected.flags ++ [
      "-dev"
      "Vulkan0"
    ];
  };

  systemd.services.knowline = lib.mkIf (cfg.enable && frontend) {
    description = "KnowLine /v1/systemone in front of llama-server";
    after = [ "llama-cpp.service" ];
    bindsTo = [ "llama-cpp.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${lib.getExe pkgs.knowline} http://127.0.0.1:${toString llamaPort} 0.0.0.0 ${toString port}";
      DynamicUser = true;
    };
  };

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = lib.optionals cfg.enable [ port ];

  environment = {
    sessionVariables.LLAMA_CACHE = modelDir;
    systemPackages = [ llamaPkg ];
  };
}
