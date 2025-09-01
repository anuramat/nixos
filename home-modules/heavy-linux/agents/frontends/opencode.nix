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
      enabledServers = { inherit (rawServers) ddg nixos; };
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
        agents.mkPrompts "opencode/commands" adaptedCommands;
    in
    (
      {
        "opencode/AGENTS.md".text = agents.instructions.generic;
        "opencode/plugin/notifications.js".text = notifications;
      }
      // commands
    );

  home = {
    packages = [
      pkgs.opencode
      (agents.mkSandbox {
        wrapperName = "ocd";
        package = pkgs.opencode;
      })
    ];

    activation = {
      opencodeSettings = config.lib.home.json.set {
        inherit mcp;
        instructions = [
          "AGENTS.md"
        ];
        share = "disabled";
        keybinds = {
          editor_open = "<leader>ctrl+e,<leader>e";
        };
        provider.anthropic.models.claude-sonnet-4-20250514.options.thinking = {
          type = "enabled";
          budgetTokens = 1024;
        };
      } (config.xdg.configHome + "/opencode/opencode.json");
    };
  };
}
