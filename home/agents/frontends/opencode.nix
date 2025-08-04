{
  pkgs,
  lib,
  config,
  ...
}:
let

  inherit (config.lib.agents) mkPrompts;
  inherit (lib) mapAttrs;
  toJSON = lib.generators.toJSON { };

  roleFiles =
    let
      readOnlyTools = "{ write: false, edit: false, bash: false }";
    in
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

  opencodeConfig = {
    instructions = config.lib.agents.contextFiles;
  };

in
{

  home = {
    packages = [
      pkgs.opencode
      (config.lib.agents.mkSandbox {
        wrapperName = "ocd";
        package = pkgs.opencode;
      })
    ];
  };
  xdg.configFile = {
    "opencode/opencode.json" = {
      text = toJSON opencodeConfig;
    };
  }
  // roleFiles;
}
