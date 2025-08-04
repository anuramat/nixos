# configured: 2025-08-04
# NOTE: context filename is hardcoded to AGENT.md; global -- in $HOME/.config/AGENT.md
{
  pkgs,
  lib,
  hax,
  config,
  ...
}:
let
  agentDir = "amp";
  settings = {
    amp = {
      # mcpServers = config.lib.agents.mcp.raw;
      git.commit = {
        # ampThread.enabled = false;
        coauthor.enabled = false;
      };
      updates.autoUpdate.enabled = false;
    };
  };
in
{
  home = {
    packages = [
      pkgs.amp-cli
      (config.lib.agents.mkSandbox {
        package = pkgs.amp-cli;
        wrapperName = "amp-sb";
        extraRwDirs = [
          "$HOME/.amp"
        ];
      })
    ];
    activation = {
      ampConfig = config.lib.home.json.set {
        "" = settings;
      } "${config.xdg.configHome}/${agentDir}/settings.json";
    };
  };
}
