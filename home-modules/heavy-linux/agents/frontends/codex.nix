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
        hide_agent_reasoning = false;
        show_raw_agent_reasoning = true;
        model_reasoning_summary = "detailed"; # auto/concise/detailed

        model_reasoning_effort = "medium";
        model_verbosity = "low";
        model = "gpt-5-codex";

        mcp_servers = {
          inherit (config.lib.agents.mcp.raw) ddg nix;
        };
        profiles = {
          oss = {
            model = "dummy";
            model_provider = "llama-cpp";
          };
        };
        # experimental_resume = "${codexHome}/history.jsonl";
        model_providers =
          if osConfig != null && osConfig.services.llama-cpp.enable then
            {
              llama-cpp = {
                name = "llama-cpp";
                base_url =
                  let
                    port = toString osConfig.services.llama-cpp.port;
                  in
                  "http://localhost:${port}";
                wire_api = "chat";
              };
            }
          else
            { };
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
  pkg = config.lib.agents.mkPackages {
    binName = "codex";
    package = pkgs.codex;
    args = [ "--dangerously-bypass-approvals-and-sandbox" ]; # "--search" is bloated
    inherit env;
    agentDir = null;
    extraRwDirs = [
      codexHome
    ];
  };
in
{
  home.sessionVariables = env;
  home = {
    packages = [ pkg ];
    activation = {
      codexConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run cat ${codexTomlCfg} > "${codexCfgPath}";
      '';
    };
  };
  xdg.configFile = {
    "codex/AGENTS.md" = {
      text = config.lib.agents.instructions.codex;
    };
  };
}
