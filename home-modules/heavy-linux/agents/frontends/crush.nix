# TODO refactor
{
  config,
  pkgs,
  ...
}@args:
let
  mcp = {
    # inherit (config.lib.agents.mcp.raw) think;
  };
  # lsp = config.lib.agents.lsp.file;
  options = {
    context_paths = config.lib.agents.contextFiles ++ [
      config.lib.agents.instructions.path
    ];
  };
  configPath = config.xdg.configHome + "/crush/crush.json";

  crush =
    let
      xdgWrapped = pkgs.writeShellScriptBin "crush" ''
        pathEncoded=$(pwd | base64)
        dir="${config.xdg.stateHome}/crush/$pathEncoded"
        crush -D "$dir" "$@"
      '';
    in
    config.lib.home.agenixWrapPkg xdgWrapped (t: {
      OPENAI_API_KEY = t.oai;
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
