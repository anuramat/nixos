{
  lib,
  pkgs,
  config,
  osConfig ? null,
  ...
}:
let
  inherit (lib) mapAttrs;
  inherit (config.lib) agents;

  qwen = "cerebras/qwen-3-coder-480b"; # cerebras recommends t=0.7 top_p=0.8
  glm = "zhipuai/glm-4.5";
  mini = "github-copilot/gpt-5-mini";

  local =
    let
      model = osConfig.services.llama-cpp.modelExtra;
    in
    rec {
      enabled = osConfig != null && osConfig.services.llama-cpp.enable;
      providerId = "llama-cpp";
      modelId = model.id;
      providerConfig =
        if enabled then
          {
            ${providerId} = {
              npm = "@ai-sdk/openai-compatible";
              options.baseURL = "http://localhost:${toString osConfig.services.llama-cpp.port}";
              name = "llama.cpp";
              models = {
                ${model.id}.limit = {
                  output = model.params.ctxSize;
                  context = model.params.ctxSize;
                };
              };
            };
          }
        else
          { };
    };

  opencodeConfig = {
    # model = mini; bugged -- overrides agent model on startup
    small_model = if local.enabled then "${local.providerId}/${local.modelId}" else qwen;
    inherit
      mcp
      provider
      agent
      plugin
      ;
    autoupdate = false;
    instructions = [
      "AGENTS.md"
    ];
    tools = {
      webfetch = false;
      "deepwiki_*" = false;
      "zotero_*" = false;
      "nixos_*" = false;
      "nixos_home_manager_info" = true;
      "nixos_home_manager_options_by_prefix" = true;
      "nixos_home_manager_search" = true;
      "nixos_nixhub_find_version" = true;
      "nixos_nixhub_package_versions" = true;
      "nixos_nixos_info" = true;
      "nixos_nixos_search" = true;
    };
    share = "disabled";
    keybinds = {
      editor_open = "<leader>ctrl+e,<leader>e";
    };
  };

  agent =
    let
      ro = {
        bash = false;
        patch = false;
        edit = false;
        write = false;
        task = false;
      };
    in
    {
      plan = {
        model = qwen;
        tools = ro;
      };
      build = {
        model = glm;
      };
      general = {
        model = qwen;
      };

      example = {
        disable = true;
        mode = "subagent";
        description = "";
        prompt = "you are...";
        # prompt = "{file:./prompts/build.txt}";
      };
      # TODO github has some useful stuff -- resources mainly; wait for https://github.com/sst/opencode/issues/806
      zotero = {
        mode = "primary";
        disable = true;
        tools = ro // {
          "zotero_*" = true;
        };
      };
      deepwiki = {
        mode = "primary";
        disable = true;
        tools = ro // {
          deepwiki_ask_question = true;
          deepwiki_read_wiki_structure = true;
        };
      };
    };

  provider =
    let
      keys = mapAttrs (n: v: "{file:${v.path}}") osConfig.age.secrets;
      gpt5models =
        let
          gptOutputOptions = {
            reasoningEffort = "medium";
            textVerbosity = "low";
          };
        in
        {
          gpt-5.options = gptOutputOptions;
          gpt-5-mini.options = gptOutputOptions;
        };
      baseModel = {
        attachment = false;
        reasoning = true;
        temperature = true;
        tool_call = true;
      };
    in
    local.providerConfig
    // {
      anthropic.models.claude-sonnet-4-20250514.options.thinking = {
        type = "enabled";
        budgetTokens = 10000;
      };
      litellm = {
        npm = "@ai-sdk/openai-compatible";
        options = {
          baseURL = "http://localhost:11333";
          apiKey = "dummy";
        };
        models =
          let
            gpt = baseModel // {
              limit = rec {
                context = 131072;
                output = context;
              };
            };
          in
          {
            "ollama/qwen3-coder:480b-cloud" = {
            };
            "ollama/gpt-oss:20b-cloud" = gpt // {
            };
            "ollama/gpt-oss:120b-cloud" = gpt // {
            };
            "ollama/deepseek-v3.1:671b-cloud" = baseModel // {
              limit = rec {
                context = 163840;
                output = context;
              };
            };
            "zai/glm-4.5" = baseModel // { }; # TODO
          };
      };
      ollama-turbo = {
        name = "Ollama Turbo";
        npm = "ollama-ai-provider-v2";
        options = {
          baseURL = "https://ollama.com/api";
          headers.Authorization = "Bearer ${keys.ollama}";
        };
        models = {
          "kimi-k2:1t" = {
          };
        };
      };
      openrouter.options.apiKey = keys.openrouter;
      zai-coding-plan.options.apiKey = keys.zai;
      cerebras = {
        options.apiKey = keys.cerebras;
        models = {
          qwen-3-235b-a22b-thinking-2507 = baseModel // {
            limit = rec {
              context = 131000;
              output = context;
            };
          };
        };
      };
      groq.options.apiKey = keys.groq;
      github-copilot.models = gpt5models;
      # openai = {
      #   options.apiKey = keys.openai;
      #   models = gpt5models;
      # };
      openai = {
        options = {
          reasoningEffort = "medium";
          reasoningSummary = "detailed"; # auto
          textVerbosity = "low";
          include = [
            "reasoning.encrypted_content"
          ];
        };
        models = {
          gpt-5-codex-low-oauth = {
            name = "GPT-5 Codex Low (OAuth)";
            options = {
              reasoningEffort = "low";
            };
          };
          gpt-5-codex-medium-oauth = {
            name = "GPT-5 Codex Medium (OAuth)";
            options = {
              reasoningEffort = "medium";
            };
          };
          gpt-5-codex-high-oauth = {
            name = "GPT-5 Codex High (OAuth)";
            options = {
              reasoningEffort = "high";
            };
          };
        };
      };
    };
  plugin = [
    "opencode-openai-codex-auth@2.1.1"
  ];
  mcp =
    let
      rawServers = mapAttrs (
        name: server:
        if server ? type && server.type == "http" then
          {
            type = "remote";
            url = server.url;
          }
        else
          {
            type = "local";
            command = [ server.command ] ++ (server.args or [ ]);
            environment = server.env or { };
          }
      ) config.lib.agents.mcp.raw;
      enabledServers = {
        inherit (rawServers)
          ddg
          deepwiki
          zotero
          nix
          ;
      };
      disabledServers =
        rawServers
        |> lib.filterAttrs (n: _: !lib.hasAttr n enabledServers)
        |> lib.mapAttrs (_: v: v // { enabled = false; });
    in
    enabledServers // disabledServers;

  notifications = # javascript
    ''
      export const NotificationPlugin = async ({ client, $ }) => {
      	return {
      		event: async ({ event }) => {
      			// Send notification on session completion
      			if (event.type === "session.idle") {
      				await $`notify-send -a opencode "OpenCode" Session completed!"`;
      			}
      		},
      	};
      };
    '';
  pkg = agents.mkPackages {
    agentDir = "opencode";
    package = pkgs.opencode;
  };
in
{
  xdg.configFile =
    let
      # TODO put into config file as well
      commands =
        let
          adaptedCommands = agents.commands |> mapAttrs (n: v: v.withFM { inherit (v) description; });
        in
        agents.mkPrompts "opencode/command" adaptedCommands;
    in
    (
      {
        "opencode/AGENTS.md".text = agents.instructions.generic;
        "opencode/plugin/notifications.js".text = notifications;
      }
      // commands
    );

  home = {
    activation = {
      opencodeSettings = config.lib.home.json.set opencodeConfig (
        config.xdg.configHome + "/opencode/opencode.json"
      );
    };
    packages = [ pkg ];
  };
}
