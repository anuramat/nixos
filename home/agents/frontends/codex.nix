{
  lib,
  pkgs,
  config,
  ...
}:
let
  # TODO use jq for toml?
  codexHomeRelative = ".codex";
  codexHomeRoot = config.home.homeDirectory;
  codexHome = codexHomeRoot + "/" + codexHomeRelative; # TODO change and propagate env
  codexCfgPath = codexHome + "/config.toml";
  codexTomlCfg =
    let
      # https://github.com/openai/codex/blob/main/codex-rs/config.md
      cfg = {
        mcp_servers = config.lib.agents.mcp.raw;
        model_providers.GHCP = {
          name = "GHCP";
          base_url = "http://localhost:${config.lib.agents.api.port}";
        };
        approval_policy = "never";
        profile = "gpt";
        profiles = {
          gpt = {
            model = "gpt-4.1";
            model_provider = "GHCP";
          };
          sonnet = {
            model = "claude-sonnet-4";
            model_provider = "GHCP";
          };
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
        copilot = true;
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
    # TODO use derivation instead of text (here and everywhere else we use global instructions)
    file.${codexHomeRelative + "/AGENTS.md"} = {
      inherit (config.lib.agents.instructions) text;
    };
  };
}
