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

  mcp = {
    # TODO nvim mcp: provides lsp most importantly, formatter (can be replaced with a commit hook), maybe more
    # TODO rag?
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
    # playwright = {
    #   command = getExe pkgs.playwright-mcp;
    # };
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
