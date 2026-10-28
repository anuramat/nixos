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
      (old: {
        doCheck = false;
        # /completion's noncausal_suffix: the block-bidirectional attention of mammoth-1
        patches = (old.patches or [ ]) ++ [ ./llama-cpp-noncausal-suffix.patch ];
      });
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
  # Base Labs' decision models (GGUF files by mradermacher), served as they were trained, with a
  # block-bidirectional mask on the full-attention layers
  baselabs = name: rev: configHash: rec {
    filename = "${name}.Q8_0.gguf";
    # in tokens of 32x32 px: llama.cpp's default maximum (4.2 MP), over which the front end refuses
    # images: at the image processor's 16384 (16.7 MP), the vision encoder's GPU work hit the
    # kernel's compute timeout (ErrorDeviceLost)
    imageMaxTokens = 4096;
    flags = [
      "--mmproj"
      "${modelDir}/${name}.mmproj-f16.gguf"
      "--image-max-tokens"
      (toString imageMaxTokens)
      "-fa"
      "on"
      # the trained length, over which the front end refuses requests
      "-c"
      "16384"
      # one slot, so that a request's questions continue from the cached state and images;
      # llama-server caches per slot, and parallel slots would each recompute them
      "-np"
      "1"
      # the prefix and each question are blocks of non-causal attention, each decoded in one ubatch
      "-b"
      "16384"
      "-ub"
      "16384"
    ];
    # the checkpoint's tokenizer, chat template and image processor, and its config.json, whose
    # block-bidirectional mask makes qev send each question as noncausal_suffix
    files = pkgs.linkFarm name (
      lib.mapAttrsToList
        (file: hash: {
          name = file;
          path = pkgs.fetchurl {
            url = "https://huggingface.co/baselabs/${name}/resolve/${rev}/${file}";
            inherit hash;
          };
        })
        {
          "config.json" = configHash;
          # the same for mammoth-1 and elephant-1
          "tokenizer.json" = "sha256-pc2XMrrc5B3lfm786DApMN7RwRiMX4H+sr1sJMShlB8=";
          "tokenizer_config.json" = "sha256-KYTANCWijSQnROI0pQA3hv0omzcT23n+CVjGXrWdhbI=";
          "chat_template.jinja" = "sha256-pK7or88uBxGULPhIiZvmYBb40UqIn/nt4HvKCZwo9xU=";
          "processor_config.json" = "sha256-v7wkr1mj5zqc0GU7jUrnWN+uxOPmwV37HGyO6NVoPIU=";
        }
    );
    # OneJev's server, the one these models were trained and served with
    frontend = url: [
      (lib.getExe pkgs.qev)
      "serve"
      "--llama-url"
      url
      "--tokenizer"
      "${files}"
      "--max-branch-tokens"
      "16384"
      "--max-image-tokens"
      (toString imageMaxTokens)
      "--name"
      name
      "--host"
      "0.0.0.0"
      "--port"
      (toString decisionPort)
    ];
  };
  # served on /v1/systemone
  decisionModels = {
    mammoth =
      baselabs "mammoth-1" "61cec44c281c693992e3d6ebeb44dd3402dfa186"
        "sha256-urWozrc/1qjxka+vI6+/aJ2THaWzx8nVFTzx5LUCRQI=";
    # the 9B sibling: 2-3x faster here, and less accurate (Jev Decision Index 0.4: 60.3, against
    # mammoth-1's 68.4)
    elephant =
      baselabs "elephant-1" "b3f8a93462fb1051a9de031e94a7ff380e254072"
        "sha256-8mMkWJ0Vky4nQtuxPbx8Vhhlzk+AmQrzt9/wXv5Nras=";
  };
  llmEnable = false;
  llm = llms.oss120;
  decision = decisionModels.elephant;

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
  # llama-server listens locally, behind the front end
  decisionServer = {
    model = decision;
    host = "127.0.0.1";
    port = decisionPort + 1;
  };
in
{
  systemd.services = {
    llama-llm = lib.mkIf llmEnable (llamaServer {
      model = llm;
      host = "0.0.0.0";
      inherit port;
    });
    llama-decision = llamaServer decisionServer // {
      # bindsTo stops the front end with llama-server; this starts it again once llama-server
      # is back, e.g. restarted on failure
      upholds = [ "decision-frontend.service" ];
    };
    decision-frontend = {
      description = "/v1/systemone in front of llama-server: ${decision.filename}";
      after = [ "llama-decision.service" ];
      bindsTo = [ "llama-decision.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = utils.escapeSystemdExecArgs (
          decision.frontend "http://127.0.0.1:${toString decisionServer.port}"
        );
        DynamicUser = true;
        # qev reads llama-server's props when it starts, which fails while the model is loading
        Restart = "on-failure";
        RestartSec = 5;
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
