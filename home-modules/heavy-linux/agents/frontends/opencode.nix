{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) mapAttrs;
  inherit (config.lib) agents;

  # Commands configuration similar to Claude
  commands =
    let
      adaptedCommands = agents.commands |> mapAttrs (n: v: v.withFM { inherit (v) description; });
    in
    agents.mkPrompts "opencode/commands" adaptedCommands;

  # Permissions configuration
  permissions = {
    # TODO: Implement proper permissions when OpenCode supports them
    edit = "auto"; # or "manual", "disabled"
    bash = "auto"; # or "manual", "disabled"
  };

  # MCP servers configuration
  mcpServers =
    let
      servers = config.lib.agents.mcp.raw;
    in
    # Transform to OpenCode format
    mapAttrs (
      name: server:
      if server ? type && server.type == "http" then
        {
          type = "remote";
          url = server.url;
          headers = server.headers or { };
          enabled = true;
        }
      else
        {
          type = "local";
          command = server.command;
          environment = server.env or { };
          enabled = true;
        }
    ) servers;

  # OpenCode configuration
  opencodeConfig = {
    "$schema" = "https://opencode.ai/config.json";
    instructions = [
      "AGENTS.md"
      "CLAUDE.md" # Also include project-specific instructions
    ];
    mcp = mcpServers;
    inherit permissions;
    # TODO: Add more configuration options as needed:
    # theme = "opencode";
    # autoupdate = false;
    # sharing = "manual";
    # formatters = { };
    # keybinds = { };
  };

  cfgDir = config.xdg.configHome + "/opencode";
in
{
  xdg.configFile = (
    {
      "opencode/AGENTS.md".text = agents.instructions.generic;
      "opencode/CLAUDE.md".text = agents.instructions.claude or agents.instructions.generic;
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

    sessionVariables = {
      # Set config directory if OpenCode supports it
      OPENCODE_CONFIG_DIR = cfgDir;
    };
  };
}
