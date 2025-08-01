{
  pkgs,
  hax,
  lib,
  config,
  ...
}:
let
  settings = {
    instructions = config.lib.agents.contextFiles;
  };
  inherit (config.lib.agents) mkPrompts;
  inherit (lib) mapAttrs;

  readOnlyTools = "{ write: false, edit: false, bash: false }";
  roles =
    config.lib.agents.roles
    |> mapAttrs (
      n: v:
      v.withFM {
        inherit (v) description;
        model = "github-copilot/gpt-4.1";
        tools = if v.readonly then readOnlyTools else null;
      }
    )
    |> mkPrompts "opencode/agents";
in
{
  home = {
    packages = [
      (config.lib.agents.mkSandbox {
        wrapperName = "ocd";
        package = pkgs.opencode;
      })
    ];
    activation = {
      opencodeConfig = config.lib.home.jsonUpdate {
        "." = settings;
      } "${config.xdg.configHome}/opencode/opencode.json";
    };
  };
  xdg.configFile = { } // roles;
}
