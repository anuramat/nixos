{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) mapAttrs';
  inherit (config.lib) agents;

  codexHome = config.xdg.configHome + "/codex";
  codexCfgPath = codexHome + "/config.toml";

  skillFiles =
    agents.commands
    |> mapAttrs' (
      n: v: {
        name = "codexSkill-" + n;
        value =
          let
            text = v.withFM {
              name = n;
              inherit (v) description;
            };
            file = pkgs.writeTextFile {
              name = "${n}-SKILL.md";
              inherit text;
            };
          in
          config.lib.home.mkGenericActivationScript file (codexHome + "/skills/${n}/SKILL.md");
      }
    );

  codexTomlCfg =
    let
      cfg = {
        notice = {
          hide_full_access_warning = true;
        };
        hide_agent_reasoning = false;
        show_raw_agent_reasoning = true;
        model_reasoning_summary = "detailed";

        model_reasoning_effort = "xhigh";
        plan_mode_reasoning_effort = "xhigh";

        model_verbosity = "low";
        model = "gpt-5.5";

        web_search = "live"; # "disabled" | "cached" | "live"
        service_tier = "fast"; # "fast" | unset

        features = {
          multi_agent = true;
          prevent_idle_sleep = false;
          personality = true;
          apps = false; # chatgpt apps
          steer = true; # interrupt by sending a message
          unified_exec = false; # background bash
          shell_snapshot = true; # persist shell
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
  codex = config.lib.agents.mkPackages {
    binName = "codex";
    package = pkgs.codex;
    args = [ "--dangerously-bypass-approvals-and-sandbox" ];
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
    packages = [
      codex
      pkgs.ccusage-codex
    ];
    activation = {
      codexConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run cat ${codexTomlCfg} > "${codexCfgPath}";
      '';
    }
    // skillFiles;
  };
  xdg.configFile = {
    "codex/AGENTS.md" = {
      text = config.lib.agents.instructions.codex;
    };
  };
}
