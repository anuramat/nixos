{
  lib,
  pkgs,
  utils,
  inputs,
  ...
}:
let
  # the servers run on Vulkan0: skip the HIP backend that config.rocmSupport adds (built for
  # every GPU arch), the per-ISA CPU backends, and the tests, which only cover the CPU
  llamaPkg =
    (pkgs.llama-cpp.override {
      vulkanSupport = true;
      rocmSupport = false;
      cpuArchDynamicDispatch = false;
    }).overrideAttrs
      { doCheck = false; };
  modelDir = "/mnt/storage/llama-cpp";
  inherit (inputs.self.consts.llama) port decisionPort;

  llms = {
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
  # served on /v1/systemone
  decisionModels = {
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
  llmEnable = false;
  llm = llms.oss120;
  decision = decisionModels.knowline;
  frontend = decision.frontend or false;

  llamaServer =
    {
      model,
      host,
      port,
    }:
    {
      description = "llama.cpp server: ${model.filename}";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = utils.escapeSystemdExecArgs (
          [
            (lib.getExe' llamaPkg "llama-server")
            "--host"
            host
            "--port"
            (toString port)
            "-m"
            "${modelDir}/${model.filename}"
          ]
          ++ model.flags
          ++ [
            "-dev"
            "Vulkan0"
          ]
        );
        DynamicUser = true;
        Restart = "on-failure";
      };
    };
  # with a front end, llama-server listens locally behind it
  decisionServer = {
    model = decision;
    host = if frontend then "127.0.0.1" else "0.0.0.0";
    port = if frontend then decisionPort + 1 else decisionPort;
  };
in
{
  systemd.services = {
    llama-llm = lib.mkIf llmEnable (llamaServer {
      model = llm;
      host = "0.0.0.0";
      inherit port;
    });
    llama-decision = llamaServer decisionServer;
    knowline = lib.mkIf frontend {
      description = "KnowLine /v1/systemone in front of llama-server";
      after = [ "llama-decision.service" ];
      bindsTo = [ "llama-decision.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${lib.getExe pkgs.knowline} http://127.0.0.1:${toString decisionServer.port} 0.0.0.0 ${toString decisionPort}";
        DynamicUser = true;
      };
    };
  };

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
    decisionPort
  ]
  ++ lib.optional llmEnable port;

  environment = {
    sessionVariables.LLAMA_CACHE = modelDir;
    systemPackages = [ llamaPkg ];
  };
}
