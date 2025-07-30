{
  lib,
  osConfig,
  hax,
  pkgs,
  ...
}:
let
  toJSON = lib.generators.toJSON { };
  inherit (lib) getExe;

  githubPatched = hax.common.patchedBinary pkgs {
    name = "GITHUB_PERSONAL_ACCESS_TOKEN";
    token = osConfig.age.secrets.ghmcp.path;
    package = pkgs.github-mcp-server;
  };

  mcpServers = {
    # TODO nvim mcp: provides lsp most importantly, formatter (can be replaced with a commit hook), maybe more
    # TODO rag?
    nixos = {
      command = getExe pkgs.mcp-nixos;
    };
    github = {
      command = githubPatched;
      args = [
        "stdio"
      ];
    };
    # playwright = {
    #   command = getExe pkgs.playwright-mcp;
    # };
  };
in
{
  lib.agents.mcp = {
    json = rec {
      raw = mcpServers;
      text = toJSON mcpServers;
      filepath = pkgs.writeTextFile {
        name = "mcp_servers.json";
        inherit text;
      };
    };
  };
}
