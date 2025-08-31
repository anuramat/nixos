{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) mapAttrs;
  inherit (config.lib) agents;

  commands =
    let
      adaptedCommands = agents.commands |> mapAttrs (n: v: v.withFM { inherit (v) description; });
    in
    agents.mkPrompts "opencode/commands" adaptedCommands;

  mcpServers = mapAttrs (
    name: server:
    if server ? type && server.type == "http" then
      {
        type = "remote";
        url = server.url;
        enabled = false;
      }
    else
      {
        type = "local";
        command = [ server.command ] ++ (server.args or [ ]);
        environment = server.env or { };
        enabled = false;
      }
  ) config.lib.agents.mcp.raw;

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

  opencodeConfig = {
    instructions = [
      "AGENTS.md"
    ];
    mcp = {
      inherit (mcpServers) duckduckgo;
    };
    share = "disabled";
    # formatters = { };
    keybinds = {
      editor_open = "<leader>ctrl+e";
    };
  };

  cfgDir = config.xdg.configHome + "/opencode";
  opencode = config.lib.home.agenixWrapPkg pkgs.opencode (
    (t: {
      inherit (t)
        openrouter
        ;
    })
  );
in
{
  xdg.configFile = (
    {
      "opencode/AGENTS.md".text = agents.instructions.generic;
      "opencode/plugin/notifications.js".text = notifications;
    }
    // commands
  );

  home = {
    packages = [
      opencode
      (agents.mkSandbox {
        wrapperName = "ocd";
        package = opencode;
      })
    ];

    activation = {
      opencodeSettings = config.lib.home.json.set opencodeConfig "${cfgDir}/opencode.json";
    };
  };
}
