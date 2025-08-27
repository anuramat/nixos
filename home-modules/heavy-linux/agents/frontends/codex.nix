{
  lib,
  pkgs,
  config,
  osConfig,
  ...
}:
let
  codexHome = config.xdg.configHome + "/codex";
  codexCfgPath = codexHome + "/config.toml";
  codexTomlCfg =
    let
      # https://github.com/openai/codex/blob/main/codex-rs/config.md
      cfg = {
        # mcp_servers = { inherit (config.lib.agents.mcp.raw) zotero; };
        profiles = {
          high = {
            model_reasoning_effort = "high";
            model_provider = "openai";
          };
          low = {
            model_reasoning_effort = "low";
            model_provider = "openai";
          };
          oss = {
            model = "dummy";
            model_provider = "llama-cpp";
          };
        };
        model_providers.llama-cpp = {
          name = "llama-cpp";
          base_url =
            let
              port = toString osConfig.services.llama-cpp.port;
            in
            "http://localhost:${port}";
          wire_api = "chat";
        };
        notify =
          let
            notifier = pkgs.writeShellApplication {
              name = "codex-notifier";
              runtimeInputs = with pkgs; [
                jq
                findutils
                libnotify
              ];
              text = ''
                notify-send -a codex "Codex" "$(jq .last-assistant-message -r)"
              '';
            };
          in
          [ notifier ];
      };
    in
    (pkgs.formats.toml { }).generate "codex-config.toml" cfg;
  env = {
    CODEX_HOME = codexHome;
  };
in
{
  home.sessionVariables = env;
  home = {
    packages = [
      pkgs.codex
      (config.lib.agents.mkSandbox {
        binName = "codex";
        package = pkgs.codex;
        args = " --dangerously-bypass-approvals-and-sandbox";
        inherit env;
        agentDir = null;
        wrapperName = "cdx";
        extraRwDirs = [
          codexHome
        ];
      })
    ];
    activation = {
      codexConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run cat ${codexTomlCfg} > "${codexCfgPath}";
      '';
    };
  };
  xdg.configFile = {
    "codex/AGENTS.md" = {
      inherit (config.lib.agents.instructions) text;
    };
  };
}
