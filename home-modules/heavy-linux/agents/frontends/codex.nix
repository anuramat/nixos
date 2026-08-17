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
        tui = {
          status_line = [
            "model-with-reasoning"
            "current-dir"
            "branch-changes"
            "run-state"
            "context-remaining"
            "five-hour-limit"
            "weekly-limit"
            "total-input-tokens"
            "total-output-tokens"
          ];
          status_line_use_colors = true;
          keymap.composer = {
            queue = "alt-enter";
          };
        };
        model_reasoning_effort = "xhigh";
        plan_mode_reasoning_effort = "xhigh";

        # meh
        projects."/etc/nixos".trust_level = "trusted";
        projects."${config.home.sessionVariables.GHQ_ROOT}/github.com/anuramat/vicode".trust_level =
          "trusted";

        model_verbosity = "low";

        web_search = "live"; # "disabled" | "cached" | "live"
        service_tier = "fast"; # "fast" | unset

        features = {
          terminal_resize_reflow = true;
          multi_agent = true;
          prevent_idle_sleep = false;
          personality = true;
          apps = false; # chatgpt apps
          steer = true; # interrupt by sending a message
          unified_exec = false; # background bash
          shell_snapshot = true; # persist shell
          memories = true;
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
                notify-send -a codex Codex "$(jq -r '."last-assistant-message"' <<<"$1")"
              '';
            };
          in
          [ (lib.getExe notifier) ];
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
  config = {
    home.sessionVariables = env;
    home = {
      packages = [
        codex
        pkgs.chatgpt
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
  };
}
