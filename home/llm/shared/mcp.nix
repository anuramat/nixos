{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:
let
  toJSON = lib.generators.toJSON { };
  inherit (lib) getExe getName;

  patchedBinary =
    args:
    pkgs.writeShellScript "${getName args.package}-agenix-patched" # bash
      ''
        export ${args.name}=$(cat "${args.token}")
        ${getExe args.package} "$@"
      '';
  githubPatched = patchedBinary {
    name = "GITHUB_PERSONAL_ACCESS_TOKEN";
    token = osConfig.age.secrets.ghmcp.path;
    package = pkgs.github-mcp-server;
  };

  mcpServers = {
    # TODO sequential thinking, not on claude
    # TODO search, not on claude
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
      text = toJSON mcpServers;
      filepath = pkgs.writeTextFile {
        name = "mcp_servers.json";
        inherit text;
      };
    };
  };
}
