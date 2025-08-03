{
  pkgs,
  lib,
  config,
  ...
}:
let

  inherit (config.lib.agents) mkPrompts;
  inherit (lib) mapAttrs;

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
    activation = {
      opencodeConfig = config.lib.home.json.set opencodeConfig "${config.xdg.configHome}/opencode/opencode.json";
    };
  };

  xdg.configFile = { } // roleFiles;
  # TODO stylix and https://opencode.ai/docs/themes/

}
