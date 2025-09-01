{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib)
    getExe
    ;

  mcp = {
    nixos = {
      command = getExe pkgs.mcp-nixos;
    };
    deepwiki = {
      type = "http";
      url = "https://mcp.deepwiki.com/mcp";
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
        ZOTERO_LOCAL = "true";
      };
    };
    ddg = {
      command = getExe pkgs.duckduckgo-mcp-server;
    };
  };

in

{
  lib.agents.mcp = config.lib.home.mkJson "mcp.json" mcp;
}
