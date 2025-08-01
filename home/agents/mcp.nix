{
  lib,
  osConfig,
  config,
  pkgs,
  ...
}:
let
  toJSON = lib.generators.toJSON { };
  inherit (lib) getExe;

  githubPatched = config.lib.home.patchedBinary {
    name = "GITHUB_PERSONAL_ACCESS_TOKEN";
    token = osConfig.age.secrets.ghmcp.path;
    package = pkgs.github-mcp-server;
  };

  servers = {
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
  name = "mcp_servers.json";
in
{
  lib.agents.mcp = config.lib.home.mkJson name servers;
}
