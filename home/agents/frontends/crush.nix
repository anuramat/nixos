# TODO refactor
{
  config,
  pkgs,
  ...
}:
let
  mcp = { inherit (config.lib.agents.mcp.raw) think; };
  # lsp = config.lib.agents.lsp.file;
  options = {
    context_paths = config.lib.agents.contextFiles ++ [
      config.lib.agents.instructions.path
    ];
  };
  configPath = config.xdg.configHome + "/crush/crush.json";

  boxed = config.lib.agents.mkSandbox {
    wrapperName = "crs";
    package = pkgs.crush;
    args = "--yolo";
    copilot = true;
  };

in

{
  home = {
    packages = [
      pkgs.crush
      boxed
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
