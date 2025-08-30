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
        command = [ server.command ] ++ server.args;
        environment = server.env or { };
        enabled = false;
      }
  ) config.lib.agents.mcp.raw;

  opencodeConfig = {
    instructions = [
      "AGENTS.md"
    ];
    # mcp = mcpServers;
    sharing = "disabled";
    # formatters = { };
    keybinds = {
      editor_open = "<leader>ctrl+e";
    };
  };

  cfgDir = config.xdg.configHome + "/opencode";
in
{
  xdg.configFile = (
    {
      "opencode/AGENTS.md".text = agents.instructions.generic;
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
      opencodeSettings = config.lib.home.json.set opencodeConfig "${cfgDir}/opencode.json";
    };
  };
}
