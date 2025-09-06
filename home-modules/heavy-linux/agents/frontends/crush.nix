# TODO refactor
{
  config,
  lib,
  pkgs,
  ...
}@args:
let
  mcp = {
    inherit (config.lib.agents.mcp.raw) ddg;
  };
  options = {
    context_paths = [
      "AGENTS.md"
      (pkgs.writeText "AGENTS.md" config.lib.agents.instructions.generic)
    ];
  };
  configPath = config.xdg.configHome + "/crush/crush.json";

  crush =
    let
      xdgWrapped = pkgs.writeShellScriptBin "crush" ''
        pathEncoded=$(pwd | base64)
        dir="${config.xdg.stateHome}/crush/$pathEncoded"
        ${lib.getExe pkgs.crush} -D "$dir" "$@"
      '';
    in
    config.lib.home.agenixWrapPkg xdgWrapped (t: {
      OPENAI_API_KEY = t.oai;
      OPENROUTER_API_KEY = t.openrouter;
      ZAI_API_KEY = t.zai;
    });

  crushBoxed = config.lib.agents.mkSandbox {
    wrapperName = "crs";
    package = crush;
    args = "--yolo";
  };

in

{
  home = {
    packages = [
      crush
      crushBoxed
    ];
    activation = {
      crushConfig = config.lib.home.json.set {
        inherit
          mcp
          options
          ;
      } configPath;
    };
  };
}
