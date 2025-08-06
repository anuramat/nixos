# TODO refactor
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mapAttrs filterAttrs getExe;
  inherit (builtins) tail;
  mcp = { inherit (config.lib.agents.mcp.raw) think; };
  # lsp = config.lib.agents.lsp.file;
  options = {
    context_paths = config.lib.agents.contextFiles ++ [
      config.lib.agents.instructions.path
    ];
  };
  apiName = "GHCP";
  providerFile = config.xdg.dataHome + "/crush/ghcp_provider.json";
  tokenFile = config.xdg.configHome + "/github-copilot/apps.json";
  configPath = config.xdg.configHome + "/crush/crush.json";

  models = pkgs.writeShellApplication {
    name = "crush-ghcp-models";
    runtimeInputs = with pkgs; [
      jq
      curl
    ];
    text =
      # bash
      ''
        if ! [ -s "${tokenFile}" ]; then
          echo "No GitHub Copilot token found."
          exit 1
        fi
        token=$(jq -r '.[].oauth_token' '${tokenFile}') || exit 1
        curl -L -H "Accept: application/vnd.github+json" -H "Authorization: Bearer $token" https://api.githubcopilot.com/models | jq '[.data[] |
        	{
        		id,
        		name,
        		context_window: .capabilities.limits.max_context_window_tokens,
        		default_max_tokens: .capabilities.limits.max_output_tokens,
        		supports_attachments: .capabilities.supports.vision
        	}]' >'${providerFile}'
      '';
  };

  copilotCli = [
    {
      "providers.${apiName}" = {
        type = "openai";
        base_url = "http://localhost:${config.lib.agents.api.port}";
        api_key = "dummy";
      };
    }
    {
      "providers.${apiName}.models" = {
        __path = providerFile;
      };
    }
  ];

  boxed = config.lib.agents.mkSandbox {
    wrapperName = "crs";
    package = pkgs.crush;
    args = "--yolo";
    copilot = true;
  };

in

{
  home = {
    packages = [
      pkgs.crush
      boxed
    ];
    activation = {
      crushConfig = config.lib.home.json.set {
        inherit
          mcp
          options
          ;
      } configPath;
      crushProviders = config.lib.home.json.set copilotCli "${config.xdg.dataHome}/crush/crush.json";
    };
  };
}
