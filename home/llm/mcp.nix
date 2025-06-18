{
  config,
  lib,
  pkgs,
  ...
}:
let
  toJSON = lib.generators.toJSON { };
  mcpServers = toJSON {
    NixOS = {
      type = "stdio";
      command = "mcp-nixos";
      args = [ ];
      env = { };
    };
  };
  mcpServersPath = pkgs.writeTextFile {
    name = "mcp_servers.json";
    text = mcpServers;
  };
in

{

  home.packages = with pkgs; [
    github-mcp-server
    mcp-nixos
  ];

  # TODO agenix for secrets
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
    lib.hm.dag.entryBefore [ "writeBoundary" ] # bash
      ''
        success=""
        temp=$(mktemp)
        jq --slurpfile mcp ${mcpServersPath} '.mcpServers = $mcp[0]' "${home}/.claude.json" > "$temp" && success=true
        [ -n "''${VERBOSE:+set}" ] && args+=(-print)
        [ -z "''${DRY_RUN:+set}" ] && [ -n "$success" ] && mv "$temp" "${home}/.claude.json"
      '';
}
