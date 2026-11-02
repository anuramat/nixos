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
    agents.skillFiles
    |> mapAttrs' (
      n: text: {
        name = "codexSkill-" + n;
        value = config.lib.home.mkGenericActivationScript (pkgs.writeText "${n}-SKILL.md" text) (
          codexHome + "/skills/${n}/SKILL.md"
        );
      }
    );

  notify = agents.notifyHook "codex";

  # merged into config.toml, which keeps what codex writes there, e.g. the
  # hooks' trust in hooks.state
  codexCfg = {
    hooks = {
      # also runs before the plan mode prompt
      Stop = [ (notify ''.last_assistant_message // "turn complete"'') ];
      PreToolUse = [
        (notify ".tool_input.questions[0].question" // { matcher = "^request_user_input"; })
      ];
    };
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
      # replaced by the notify hooks, which say it's codex
      notifications = false;
      keymap.composer = {
        queue = "alt-enter";
      };
    };
    model_reasoning_effort = "xhigh";
    plan_mode_reasoning_effort = "xhigh";
    model_reasoning_summary = "detailed";
    personality = "pragmatic";

    # meh
    projects."/etc/nixos".trust_level = "trusted";
    projects."${config.home.sessionVariables.GHQ_ROOT}/github.com/anuramat/vicode".trust_level =
      "trusted";

    model_verbosity = "low";

    web_search = "live"; # "disabled" | "cached" | "live"
    service_tier = "default"; # "fast" | "default"

    sandbox_mode = "workspace-write";
    sandbox_workspace_write.network_access = true;

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
      daemon_auto_start = false; # multiple instances share a single backend; NOTE causes problems because the sandbox wrapper is configured for a specific project
    };

    desktop = {
      conversationDetailMode = "STEPS_PROSE";
      sansFontSize = 14;
      codeFontSize = 13;
      ambient-suggestions-enabled = false;
      localeOverride = "en-US";
      show-context-window-usage = true;
      composerEnterBehavior = "enter";
      followUpQueueMode = "steer";
      git-pull-request-merge-method = "merge";
      reviewDelivery = "detached";
      enabled-reasoning-efforts = [
        "low"
        "medium"
        "high"
        "xhigh"
        "ultra"
        "max"
      ];
      usePointerCursors = false;
      composerPlainTextMode = true;
    };
  };
  env = {
    CODEX_HOME = codexHome;
  };
  codex = config.lib.agents.mkPackages {
    package = pkgs.codex;
    args = [ "--dangerously-bypass-approvals-and-sandbox" ];
    inherit env;
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
        codexConfig = config.lib.home.toml.set codexCfg codexCfgPath;
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
