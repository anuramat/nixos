{
  lib,
  osConfig,
  config,
  pkgs,
  ...
}:
let
  inherit (lib)
    getExe
    mapAttrs
    filterAttrs
    tail
    ;

  mcp =
    let
      nixos = {
        command = getExe pkgs.mcp-nixos;
      };
      github =
        let
          githubPatched = config.lib.home.patchedBinary {
            name = "GITHUB_PERSONAL_ACCESS_TOKEN";
            token = osConfig.age.secrets.ghmcp.path;
            package = pkgs.github-mcp-server;
          };
        in
        {
          command = githubPatched;
          args = [
            "stdio"
          ];
        };
      playwright = {
        command = getExe pkgs.playwright-mcp;
      };
    in
    {
      inherit nixos;
    };

  lsp =
    let
      servers = with config.programs.nixvim.plugins.lsp.servers; {
        go = gopls;
        nix = nil_ls;
        python = pyright;
      };
    in
    servers
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
  lib.agents.mcp = config.lib.home.mkJson "mcp.json" mcp;
  lib.agents.lsp = config.lib.home.mkJson "mcp.json" lsp;
}
