{
  config,
  lib,
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
    token = config.age.secrets.ghmcp.path;
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
    # github = {
    #   command = githubPatched;
    #   args = [
    #     "stdio"
    #   ];
    # };
    # playwright = {
    #   command = getExe pkgs.playwright-mcp;
    # };
  };
  mcpServersJSON = toJSON mcpServers;
  mcpServersPath = pkgs.writeTextFile {
    name = "mcp_servers.json";
    text = mcpServersJSON;
  };
in

{
  home.activation =
    let
      home = config.home.homeDirectory;
    in
    {
      claudeMcp =
        lib.hm.dag.entryAfter [ "writeBoundary" ] # bash
          ''
            success=""
            temp=$(mktemp)
            run ${getExe pkgs.jq} --slurpfile mcp ${mcpServersPath} '.mcpServers = $mcp[0]' "${home}/.claude.json" > "$temp" && success=true
            [ "$success" == true ] && run mv "$temp" "${home}/.claude.json"
          '';
    };
}
