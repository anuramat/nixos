{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mapAttrs filterAttrs getExe;
  inherit (builtins) tail;
  crushConfig = {
    mcp = config.lib.agents.mcp.file;
    lsp = config.lib.agents.lsp.file;
    general = {
      context_paths = config.lib.agents.contextFiles ++ [
        config.lib.agents.instructions.path
      ];
    };
  };
in
{
  home = {
    packages = [
      (config.lib.agents.mkSandbox {
        wrapperName = "crs";
        package = pkgs.crush;
        args = "--yolo";
      })
      pkgs.crush
    ];
    activation = {
      crushConfig = config.lib.home.json.set crushConfig "${config.xdg.configHome}/crush/crush.json";
    };
  };
}
