{
  lib,
  pkgs,
  config,
  osConfig ? null,
  ...
}:
let
  inherit (lib) mapAttrs getExe;
  inherit (config.lib) agents;

  qwen = "cerebras/qwen-3-coder-480b"; # cerebras recommends t=0.7 top_p=0.8
  # glm = "zhipuai/glm-4.5";
  mini = "github-copilot/gpt-5-mini";
  small_model = if local.enabled then "${local.providerId}/${local.modelId}" else qwen;

  # # TODO put into config file as well
  # roles =
  #   # let
  #   #   readOnlyTools = "{ write: false, edit: false, bash: false }";
  #   # in
  #   config.lib.agents.roles
  #   |> mapAttrs (
  #     _: v:
  #     v.withFM {
  #       inherit (v) description;
  #       model = "github-copilot/gpt-4.1";
  #       # tools = if v.readonly then readOnlyTools else null; TODO
  #     }
  #   )
  #   |> agents.mkPrompts "opencode/agents";

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
        model = mini;
      };
      general = {
        model = qwen;
      };

      example = {
        disable = true;
        mode = "subagent";
        description = "this is...";
        prompt = "you are...";
      };
    };

  tokens =
    t: with t; {
      inherit
        cerebras
        groq
        ollama
        openrouter
        zai
        ;
    };
  provider =
    let
      keys = mapAttrs (n: _: "{env:${n}}") osConfig.age.secrets;
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
        models = {
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

  # opencode debug lsp diagnostics ./path/to/file/with/error.ts
  lsp = {
    custom-lsp = {
      command = [
        (getExe pkgs.tinymist)
        "lsp"
      ];
      extensions = [
        ".typ"
      ];
    };
  };

  mcp =
    let
      rawServers = mapAttrs (
        _: server:
        if server ? type && server.type == "http" then
          {
            type = "remote";
            inherit (server) url;
          }
        else
          {
            type = "local";
            command = [ server.command ] ++ (server.args or [ ]);
            environment = server.env or { };
          }
      ) config.lib.agents.mcp.raw;
      enabledServers = {
        # NOTE waiting for mcp resources and prompt; https://github.com/sst/opencode/issues/806
        inherit (rawServers)
          ddg
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

  # # TODO put into config file as well
  # commands =
  #   let
  #     adaptedCommands = agents.commands |> mapAttrs (_: v: v.withFM { inherit (v) description; });
  #   in
  #   agents.mkPrompts "opencode/command" adaptedCommands;

in
{
  xdg.configFile = {
    "opencode/AGENTS.md".text = agents.instructions.generic;
    "opencode/plugin/notifications.js".text = notifications;
  };
  home = {
    activation.opencodeSettings = config.lib.home.json.set {
      inherit
        provider
        agent
        plugin
        small_model
        mcp
        lsp
        ;
      autoupdate = false;
      instructions = [ "AGENTS.md" ];
      tools.webfetch = false;
      share = "disabled";
      keybinds.editor_open = "<leader>ctrl+e,<leader>e";
    } (config.xdg.configHome + "/opencode/opencode.json");
    packages = [
      (agents.mkPackages {
        agentDir = "opencode";
        package = pkgs.opencode;
        inherit tokens;
        env = {
          OPENCODE_DISABLE_LSP_DOWNLOAD = "true";
        };
      })
    ];
  };
}
