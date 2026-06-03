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
        tui.keymap.composer = {
          queue = "alt-enter";
        };
        model_reasoning_effort = "xhigh";
        plan_mode_reasoning_effort = "xhigh";

        # meh
        projects."/etc/nixos".trust_level = "trusted";
        projects."/home/anuramat/.local/share/ghq/github.com/anuramat/vicode".trust_level = "trusted";

        model_verbosity = "low";
        model = "gpt-5.5";

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
  # codex remote-control
  codex-remote = config.lib.agents.mkPackages {
    wrapperName = "codex-remote";
    binName = "codex";
    package = pkgs.codex;
    args = [
      "--dangerously-bypass-approvals-and-sandbox"
      "remote-control"
    ];
    inherit env;
    agentDir = null;
    extraRwDirs = [
      codexHome
      config.home.sessionVariables.GHQ_ROOT
      "/etc/nixos"
    ];
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
      codex-remote
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
  systemd.user.services."codex-remote" = {
    Unit.Description = "codex remote control service";
    Service = {
      ExecStart = "${codex-remote}/bin/codex-remote";
      WorkingDirectory = "/tmp";
    };
  };
}
