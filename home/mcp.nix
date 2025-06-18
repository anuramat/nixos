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
  mcpServersPath = pkgs.writeTextfile {
    name = "mcp_servers.json";
    text = mcpServers;
  };
in

{
  # TODO agenix for secrets
  "mcphub/servers.json".text = toJSON {
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
        temp=$(mktemp)
        jq --slurpfile mcp ${mcpServersPath} '.mcpServers = $mcp[0]' "${home}/.claude.json" > "$temp" && mv "$temp" "${home}/.claude.json"
      '';
}
