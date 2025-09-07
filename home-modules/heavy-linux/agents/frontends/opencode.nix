{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) mapAttrs;
  inherit (config.lib) agents;

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
    packages =
      let
        opencode = config.lib.home.agenixWrapPkg pkgs.opencode (
          (t: {
            OPENROUTER_KEY = t.openrouter;
            ZAI_KEY = t.zai;
            CEREBRAS_KEY = t.cerebras-org;
            GROQ_API_KEY = t.groq;
            OLLAMA_TURBO_API_KEY = t.ollama-turbo;
          })
        );
      in
      [
        opencode
        (agents.mkSandbox {
          wrapperName = "ocd";
          package = opencode;
        })
      ];

    activation = {
      # opencodeAuth = config.lib.home.json.set {
      # } (config.xdg.dataHome + "/opencode/auth.json");
      opencodeSettings = config.lib.home.json.set {
        inherit mcp;
        autoupdate = false;
        instructions = [
          "AGENTS.md"
        ];
        share = "disabled";
        keybinds = {
          editor_open = "<leader>ctrl+e,<leader>e";
        };
        # reasoning effort for gpt5: https://github.com/sst/opencode/issues/1823
        provider = {
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
          openrouter.options.apiKey = "{env:OPENROUTER_KEY}";
          zai.options.apiKey = "{env:ZAI_KEY}"; # TODO add _API
          cerebras.options.apiKey = "{env:CEREBRAS_KEY}";
          groq.options.apiKey = "{env:GROQ_API_KEY}";
          ollama-turbo.options.apiKey = "{env:OLLAMA_TURBO_API_KEY}";
        };
      } (config.xdg.configHome + "/opencode/opencode.json");
    };
  };
}
