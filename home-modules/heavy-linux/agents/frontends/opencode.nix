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

  glm = "cerebras/zai-glm-4.7";
  # glm = "zai-coding-plan/glm-4.7";

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
      default = {
        plan = {
          model = glm;
          tools = ro;
        };
        build = {
          model = glm;
        };
        general = {
          model = glm;
        };
      };
    in
    default;

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
      # TODO tidy gpt5 models
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
          qwen-3-235b-a22b-thinking-2507 = {
            attachment = false;
            reasoning = true;
            temperature = true;
            tool_call = true;
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

  # TODO put into config file as well
  command =
    agents.commands
    |> mapAttrs (
      _: v: {
        inherit (v) description;
        template = v.text;
        # model, agent, subtask: bool
      }
    );

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
        command
        mcp
        lsp
        ;
      plugin = [
      ];
      small_model = glm;
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
