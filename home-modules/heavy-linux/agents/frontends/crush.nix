# TODO refactor
{
  config,
  lib,
  pkgs,
  ...
}@args:
let
  mcp = {
    # TODO like in ./opencode.nix
    ddg = config.lib.agents.mcp.raw.ddg // {
      type = "stdio";
    };
  };
  options = {
    context_paths = [
      "AGENTS.md"
      (pkgs.writeText "AGENTS.md" config.lib.agents.instructions.generic)
    ];
  };
  api_config = {
    providers = {
      cerebras = {
        type = "openai";
        name = "Cerebras";
        base_url = "https://api.cerebras.ai/v1";
        api_key = "$CEREBRAS_API_KEY";
        models = [
          {
            id = "qwen-3-coder-480b";
            name = "Qwen3 Coder 480B";
            context_window = 131072;
            default_max_tokens = 8192;
          }
        ];
      };
      zai-code = {
        type = "anthropic";
        name = "ZAI (plan)";
        base_url = "https://api.z.ai/api/anthropic";
        api_key = "$ZAI_API_KEY";
        models = [
          {
            id = "glm-4.5";
            name = "GLM-4.5";
            context_window = 128000;
            default_max_tokens = 50000;
            can_reason = true;
            supports_attachments = true;
          }
        ];
      };
      llama-cpp = {
        name = "llama.cpp";
        base_url = "http://localhost:11343/v1/"; # TODO reference config
        type = "openai";
        models = [
          {
            name = "dummy";
            id = "dummy";
            context_window = 131072;
            default_max_tokens = 20000;
          }
        ];
      };
    };
    models = {
      large = {
        model = "glm-4.5";
        provider = "zai-code";
      };
      small = {
        model = "dummy";
        provider = "llama-cpp";
      };
    };
  };
  configPath = config.xdg.configHome + "/crush/crush.json";

  crush =
    let
      xdgWrapped = pkgs.writeShellScriptBin "crush" ''
        pathEncoded=$(pwd | base64)
        dir="${config.xdg.stateHome}/crush/$pathEncoded"
        ${lib.getExe pkgs.crush} -D "$dir" "$@"
      '';
    in
    config.lib.home.agenixWrapPkg xdgWrapped (t: {
      OPENAI_API_KEY = t.oai;
      OPENROUTER_API_KEY = t.openrouter;
      ZAI_API_KEY = t.zai;
      CEREBRAS_API_KEY = t.cerebras-org;
    });

  crushBoxed = config.lib.agents.mkPackages {
    wrapperName = "crs";
    package = crush;
    args = "--yolo";
  };

in

{
  home = {
    packages = crushBoxed;
    activation = {
      crushConfig = config.lib.home.json.set {
        inherit
          mcp
          options
          api_config
          ;
      } configPath;
    };
  };
}
