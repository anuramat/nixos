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
      mcpServers = config.lib.agents.mcp.json.raw;
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
        extraRwDirs = [
          "$HOME/.amp"
        ];
      })
    ];
    activation = {
      ampConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] (
        hax.common.jsonUpdate pkgs "${config.xdg.configHome}/${agentDir}/settings.json" [
          {
            prop = ".";
            text = lib.generators.toJSON { } settings;
          }
        ]
      );
    };
  };
}
