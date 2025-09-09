{
  lib,
  pkgs,
  config,
  osConfig,
  ...
}:
let
  inherit (lib) mapAttrs;
  inherit (config.lib) agents;

  tokens = t: {
    OPENROUTER_API_KEY = t.openrouter;
    ZAI_API_KEY = t.zai;
    CEREBRAS_KEY = t.cerebras-org;
    GROQ_API_KEY = t.groq;
    OLLAMA_TURBO_API_KEY = t.ollama-turbo;
    OPENAI_API_KEY = t.oai;
  };

  agent =
    let
      ro = {
        bash = false;
        patch = false;
        edit = false;
        write = false;
      };

      gpt = "ollama-turbo/gpt-oss:120b";
      qwen = "cerebras/qwen-3-coder-480b";
      glm = "zhipuai/glm-4.5";
    in
    {
      plan = {
        model = gpt;
        tools = ro // {
          # "think_*" = true;
        };
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
    in
    {
      llama-cpp = {
        npm = "@ai-sdk/openai-compatible";
        options.baseURL = "http://localhost:11343";
        name = "llama.cpp";
        models.dummy.limit = {
          output = 99999999;
          context = 20000; # TODO add a common env var with llama server
        };
      };
      anthropic.models.claude-sonnet-4-20250514.options.thinking = {
        type = "enabled";
        budgetTokens = 10000;
      };
      # TODO use {file:...} instead of env
      openrouter.options.apiKey = keys.openrouter;
      zhipuai = {
        api = "https://api.z.ai/api/coding/paas/v4";
        options = {
          apiKey = keys.zai;
        };
      };
      cerebras.options.apiKey = keys.cerebras;
      groq.options.apiKey = keys.groq;
      openai = {
        options = {
          apiKey = keys.openai;
        };
        models = {
          gpt-5 = {
            options = {
              reasoningEffort = "high";
              textVerbosity = "low";
              # reasoningSummary = "auto";
              # include = [ "reasoning.encrypted_content" ];
            };
          };
        };
      };
      ollama-turbo = {
        name = "Ollama Turbo";
        npm = "ollama-ai-provider-v2";
        options = {
          baseURL = "https://ollama.com/api";
          headers = {
            Authorization = "Bearer ${keys.ollama}";
          };
        };
        models =
          let
            common = {
              attachment = false;
              reasoning = true;
              temperature = true;
              tool_call = true;
            };
            gpt =
              effort:
              common
              // {
                options = {
                  reasoningEffort = effort;
                  think = effort;
                  effort = effort;
                  reasoning_effort = effort;
                };
                limit = rec {
                  context = 131072;
                  output = context;
                };
              };
            small =
              effort:
              (gpt effort)
              // {
                id = "gpt-oss:20b";
                name = "GPT-OSS 20B (${effort})";
              };
            big =
              effort:
              (gpt effort)
              // {
                id = "gpt-oss:120b";
                name = "GPT-OSS 120B (${effort})";
              };
          in
          {
            "gpt-oss:20b" = small "high";
            "gpt-oss:120b" = big "high";
            "deepseek-v3.1:671b" = common // {
              limit = rec {
                context = 131072;
                output = context;
              };
            };
          };
      };
    };
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
          think
          deepwiki
          zotero
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
      opencodeSettings = config.lib.home.json.set {
        model = "cerebras/qwen-3-coder-480b";
        # small_model = "github-copilot/gpt-4.1";
        small_model = "llama-cpp/dummy";
        inherit mcp provider agent;
        autoupdate = false;
        instructions = [
          "AGENTS.md"
        ];
        tools = {
          webfetch = false;
          "deepwiki_*" = false;
          "think_*" = false;
          "zotero_*" = false;
        };
        share = "disabled";
        keybinds = {
          editor_open = "<leader>ctrl+e,<leader>e";
        };
      } (config.xdg.configHome + "/opencode/opencode.json");
    };

    packages = agents.mkPackages {
      wrapperName = "ocd";
      package = pkgs.opencode;
      inherit tokens;
    };
  };
}
# "models": {
#   "glm-4.5": {
#     "limit": {
#       "context": 131072,
#       "output": 98304
#     },
#     "temperature": true,
#     "tool_call": true,
#     "reasoning": true
#   }
# }
