{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mapAttrs
    filterAttrs
    getExe
    ;
  inherit (builtins)
    tail
    ;
  lsp =
    let
      servers =
        config.programs.nixvim.plugins.lsp.servers
        |> filterAttrs (n: v: v.enable)
        |> mapAttrs (
          n: v: {
            command = getExe v.package;
            args = if v.cmd == null then [ ] else tail v.cmd;
            options = v.settings;
          }
        );
    in
    {
      go = servers.gopls;
      nix = servers.nil-ls;
      python = servers.pyright;
    };
  mcp = config.lib.agents.mcp.json.file;
  general = {
    context_paths = config.lib.agents.contextFiles ++ [
      config.lib.agents.instructions.path
    ];
    # tui.compact_mode = true;
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
