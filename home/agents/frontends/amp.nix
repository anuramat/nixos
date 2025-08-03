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
      mcpServers = config.lib.agents.mcp.raw;
      git.commit = {
        ampThread.enabled = false;
        coauthor.enabled = false;
      };
    };
  };
in
{
  home = {
    packages = [
      (config.lib.agents.mkSandbox {
        package = pkgs.amp-cli;
        wrapperName = "amp";
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
  # NOTE: global .config/AGENT.md is hardcoded in `amp`
  # I think that's all settings they have for now
}
