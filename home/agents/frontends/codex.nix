{
  lib,
  pkgs,
  config,
  ...
}:
let
  # TODO use jq for toml?
  codexHome = config.home.homeDirectory + "/.codex"; # TODO change and propagate env
  codexCfgPath = codexHome + "/config.toml";
  codexTomlCfg =
    let
      # https://github.com/openai/codex/blob/main/codex-rs/config.md
      cfg = {
        mcp_servers = config.lib.agents.mcp.raw;
        model_provider = "GHCP";
        model_providers.GHCP = {
          name = "GHCP";
          base_url = "http://localhost:${config.lib.agents.api.port}";
          env_key = "dummy";
          # wire_api = "chat" or "responses";
        };
        approval_policy = "never";
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
                notify-send "Codex" "$(jq .last-assistant-message -r)"
              '';
            };
          in
          [ notifier ];
      };
    in
    (pkgs.formats.toml { }).generate "codex-config.toml" cfg;
in
{
  home = {
    packages = [
      (config.lib.agents.mkSandbox {
        binName = "codex";
        package = pkgs.codex;
        args = "--full-auto";
        agentDir = null;
        wrapperName = "cdx";
        # https://github.com/openai/codex/blob/main/codex-rs/config.md
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
}
