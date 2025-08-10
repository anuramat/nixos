# TODO refactor
{
  config,
  pkgs,
  ...
}@args:
let
  mcp = { inherit (config.lib.agents.mcp.raw) think; };
  # lsp = config.lib.agents.lsp.file;
  options = {
    context_paths = config.lib.agents.contextFiles ++ [
      config.lib.agents.instructions.path
    ];
  };
  configPath = config.xdg.configHome + "/crush/crush.json";

  withTokens = config.lib.home.agenixWrapPkg pkgs.crush (t: {
    OPENAI_API_KEY = t.oai;
  });

  boxed = config.lib.agents.mkSandbox {
    wrapperName = "crs";
    package = withTokens;
    args = "--yolo";
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
