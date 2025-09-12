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

  oss = "ollama-turbo/gpt-oss:120b";
  qwen = "cerebras/qwen-3-coder-480b";
  glm = "zhipuai/glm-4.5";
  gpt41 = "github-copilot/gpt-4.1";

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
              options.baseURL = "http://localhost:${osConfig.services.llama-cpp.port}";
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
    model = "cerebras/qwen-3-coder-480b";
    small_model = if local.enabled then "${local.providerId}/${local.modelId}" else gpt41;
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
  };

  agent =
    let
      ro = {
        bash = false;
        patch = false;
        edit = false;
        write = false;
      };
    in
    {
      plan = {
        model = oss;
        tools = ro // {
          # "think_*" = true;
        };
      };
      build = {
        model = oss;
      };
      general = {
        model = oss;
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
    local.providerConfig
    // {
      anthropic.models.claude-sonnet-4-20250514.options.thinking = {
        type = "enabled";
        budgetTokens = 10000;
      };
      openrouter.options.apiKey = keys.openrouter;
      zhipuai = {
        api = "https://api.z.ai/api/coding/paas/v4";
        options.apiKey = keys.zai;
      };
      cerebras.options.apiKey = keys.cerebras;
      groq.options.apiKey = keys.groq;
      openai = {
        options.apiKey = keys.openai;
        models.gpt-5.options = {
          reasoningEffort = "high";
          textVerbosity = "low";
        };
      };
      ollama-turbo = {
        name = "Ollama Turbo";
        npm = "ollama-ai-provider-v2";
        options = {
          baseURL = "https://ollama.com/api";
          headers.Authorization = "Bearer ${keys.ollama}";
        };
        models =
          let
            common = {
              attachment = false;
              reasoning = true;
              temperature = true;
              tool_call = true;
            };
            gpt = common // {
              limit = rec {
                context = 131072;
                output = context;
              };
            };
          in
          {
            "gpt-oss:20b" = gpt // {
              id = "gpt-oss:20b";
              name = "GPT-OSS 20B";
            };
            "gpt-oss:120b" = gpt // {
              id = "gpt-oss:120b";
              name = "GPT-OSS 120B";
            };
            "deepseek-v3.1:671b" = common // {
              limit = rec {
                context = 163840;
                output = context;
              };
            };
          };
      };
    }

  ;
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
      opencodeSettings = config.lib.home.json.set opencodeConfig (
        config.xdg.configHome + "/opencode/opencode.json"
      );
    };

    packages = agents.mkPackages {
      wrapperName = "ocd";
      package = pkgs.opencode;
    };
  };
}
