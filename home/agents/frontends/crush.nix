{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mapAttrs filterAttrs getExe;
  inherit (builtins) tail;
  lsp =
    with config.programs.nixvim.plugins.lsp.servers;
    {
      go = gopls;
      nix = nil-ls;
      python = pyright;
    }
    |> filterAttrs (n: v: v.enable)
    |> mapAttrs (
      n: v: {
        command = getExe v.package;
        args = if v.cmd == null then [ ] else tail v.cmd;
        options = v.settings;
      }
    );
  mcp = config.lib.agents.mcp.json.file;
  general = {
    context_paths = config.lib.agents.contextFiles ++ [
      config.lib.agents.instructions.path
    ];
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
    ];
    # TODO subasians
    # TODO commands
    activation = {
      crushConfig = config.lib.home.jsonUpdate {
        ".mcp" = mcp;
        ".lsp" = lsp;
        ".options" = general;
      } "${config.xdg.configHome}/crush/crush.json";
    };
  };
}
