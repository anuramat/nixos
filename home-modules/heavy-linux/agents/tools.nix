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
    nix = {
      command = getExe pkgs.mcp-nixos;
    };
    deepwiki = {
      type = "http";
      url = "https://mcp.deepwiki.com/mcp";
    };
    perplexity =
      let
        perplexityPatched = config.lib.home.agenixWrapPkg pkgs.perplexity-mcp (t: {
          PERPLEXITY_API_KEY = t.perplexity;
        });
      in
      {
        command = getExe perplexityPatched;
      };
    # github =
    #   let
    #     githubPatched = config.lib.home.agenixWrapPkg pkgs.github-mcp-server (t: {
    #       GITHUB_PERSONAL_ACCESS_TOKEN = t.ghmcp;
    #     });
    #   in
    #   {
    #     command = getExe githubPatched;
    #     args = [
    #       "stdio"
    #     ];
    #   };
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
