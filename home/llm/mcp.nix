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
    NixOS = {
      command = getExe pkgs.mcp-nixos;
    };
    # TODO
    GitHub = {
      command = githubPatched;
      args = [
        "stdio"
      ];
    };
  };
  mcpServersJSON = toJSON mcpServers;
  mcpServersPath = pkgs.writeTextFile {
    name = "mcp_servers.json";
    text = mcpServersJSON;
  };
in

{
  home.packages = with pkgs; [
    mcp-nixos
  ];

  xdg.configFile."mcphub/servers.json".text = toJSON {
    nativeMCPServers = {
      mcphub = {
        disabled_tools = [ "toggle_mcp_server" ];
        disabled_resources = [
          "mcphub://docs"
          "mcphub://changelog"
          "mcphub://native_server_guide"
        ];
        disabled_prompts = [ "create_native_server" ];
      };
      neovim.disabled_prompts = [ "parrot" ];
    };
    inherit mcpServers;
  };

  home.activation =
    let
      home = config.home.homeDirectory;
    in
    {
      claudeMcp =
        lib.hm.dag.entryBefore [ "writeBoundary" ] # bash
          ''
            success=""
            temp=$(mktemp)
            jq --slurpfile mcp ${mcpServersPath} '.mcpServers = $mcp[0]' "${home}/.claude.json" > "$temp" && success=true
            [ -n "''${VERBOSE:+set}" ] && args+=(-print)
            [ -z "''${DRY_RUN:+set}" ] && [ -n "$success" ] && mv "$temp" "${home}/.claude.json"
          '';
    };
}
