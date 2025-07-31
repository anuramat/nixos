{
  config,
  hax,
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
  settings = {
    lsp = {
      go = servers.gopls;
      nix = servers.nil-ls;
      python = servers.pyright;
    };
    options = {
      context_paths = config.lib.agents.contextFileName;
      tui.compact_mode = true;
    };
  };
  toJSON = lib.generators.toJSON { };
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
    # TODO mcp
    # TODO subasians
    # TODO commands
    activation = {
      crushConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] (
        hax.common.jsonUpdate pkgs "${config.xdg.configHome}/crush/crush.json" [
          {
            prop = ".mcp";
            inherit (config.lib.agents.mcp.json) file;
          }
          # TODO the next two should have been a single line... refactor later
          {
            prop = ".lsp";
            text = toJSON settings.lsp;
          }
          {
            prop = ".options";
            text = toJSON settings.options;
          }
        ]
      );
    };
  };

}
