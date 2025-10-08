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
