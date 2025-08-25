{
  lib,
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
    nixos = {
      command = getExe pkgs.mcp-nixos;
    };
    github =
      let
        githubPatched = config.lib.home.agenixWrapPkg pkgs.github-mcp-server (t: {
          GITHUB_PERSONAL_ACCESS_TOKEN = t.ghmcp;
        });
      in
      {
        command = getExe githubPatched;
        args = [
          "stdio"
        ];
      };
    playwright = {
      command = getExe pkgs.playwright-mcp;
    };
    think = {
      command = getExe pkgs.gothink;
    };
    modagent = {
      command = getExe pkgs.modagent;
    };
    tools = {
      command = getExe pkgs.claude-code;
      args = [
        "mcp"
        "serve"
      ];
    };
    zotero = {
      command = getExe pkgs.zotero-mcp;
      env = {
        ZOTERO_LOCAL = true;
      };
    };
  };

  lsp =
    let
      servers = with config.programs.nixvim.plugins.lsp.servers; {
        go = gopls;
        nix = nil_ls;
        python = pyright;
        rust = rust_analyzer;
        lua = lua_ls;
        sh = bashls;
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

  # TODO is this even used anywhere?
  cli = {
    search = {
      pkg = pkgs.writeShellApplication {
        name = "search";
        runtimeInputs = with pkgs; [
          ddgr
        ];
        text = ''
          ddgr --np --unsafe --json "$@"
        '';
      };
      usage = ''
        `search` -- web search bash command; usage:

        ```bash
        search "$REQUEST"
        search -w example.com "$REQUEST"
        ```
      '';
    };
  };

in
{
  lib.agents.mcp = config.lib.home.mkJson "mcp.json" mcp;
  lib.agents.lsp = config.lib.home.mkJson "mcp.json" lsp;
  home.packages = lib.mapAttrsToList (n: v: v.pkg) cli;
  lib.agents.usage = lib.mapAttrsToList (n: v: v.usage) cli;
}
