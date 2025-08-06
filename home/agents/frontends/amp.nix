# configured: 2025-08-04
{
  pkgs,
  lib,
  hax,
  config,
  ...
}:
let
  # context filename is hardcoded to AGENT.md; global -- in $HOME/.config/AGENT.md
  agentDir = "amp";
  generalCfg = {
    amp = {
      git.commit = {
        # ampThread.enabled = false;
        coauthor.enabled = false;
      };
      updates.autoUpdate.enabled = false;
    };
  };

  boxed = config.lib.agents.mkSandbox {
    package = pkgs.amp-cli;
    wrapperName = "amp-sb";
    extraRwDirs = [
      "$HOME/.amp"
    ];
  };

in
{
  home = {
    packages = [
      pkgs.amp-cli
      boxed
    ];
    activation = {
      ampConfig = config.lib.home.json.set {
        "" = generalCfg;
      } "${config.xdg.configHome}/${agentDir}/settings.json";
    };
  };
}
