{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (config.lib) agents;

  cfgDir = config.xdg.configHome + "/claude";

  statusLine = {
    type = "command";
    command =
      let
        script = ''
          input=$(cat)
          model_display=$(echo "$input" | jq -r '.model.display_name')
          output_style=$(echo "$input" | jq -r '.output_style.name')

          starship module directory
          starship module git_branch
          starship module git_state
          starship module git_status
          echo " $model_display ($output_style)"
        '';
      in
      pkgs.writeShellScript "statusline.sh" script;
    padding = 0;
  };

  # notifies regardless of focus, unlike the built-in notifications; the
  # message is cut to stay under ntfy's size limit
  notify = jqMessage: {
    hooks = [
      {
        command = # bash
          ''jq -r '"claude: " + (${jqMessage})[:500]' | notify'';
        type = "command";
      }
    ];
  };

  hooks = {
    Stop = [ (notify ''.last_assistant_message // "turn complete"'') ];
    PreToolUse = [
      (
        notify ''if .tool_name == "ExitPlanMode" then "plan ready" else .tool_input.questions[0].question end''
        // {
          matcher = "AskUserQuestion|ExitPlanMode";
        }
      )
    ];
    # bypass mode still prompts for critical-path rm/rmdir, then auto-denies
    PermissionRequest = [
      {
        hooks = [
          {
            command = # bash
              ''jq 'select(.permission_mode == "bypassPermissions") | {hookSpecificOutput: {hookEventName: "PermissionRequest", decision: {behavior: "allow"}}}' '';
            type = "command";
          }
        ];
        matcher = "Bash";
      }
    ];
  };

  permissions = {
    allow = [ ];
    deny = [ ];
  };

  # `claude-teleport HOST [SID]`: copy a session of $PWD to the same path on
  # HOST, to be picked up there with `claude -r`; fzf picker if SID is omitted
  teleport = pkgs.writeShellApplication {
    name = "claude-teleport";
    runtimeInputs = with pkgs; [
      fzf
      jq
      rsync
      openssh
    ];
    text = ''
      host=$1
      dir=${cfgDir}/projects/''${PWD//[^[:alnum:]]/-}
      title='(map(select(.type == "ai-title").aiTitle) | last)
        // (map(select(.type == "user" and (.message.content | type) == "string").message.content) | first)
        // "" | gsub("\\s+"; " ")'
      export dir preview='select((.type == "user" or .type == "assistant") and (.isSidechain | not))
        | .type + ": " + (.message.content | if type == "string" then . else map(.text // empty) | join("\n") end)
        | select(endswith(": ") | not)'

      pick() {
        # shellcheck disable=SC2016 # the preview is expanded by fzf's shell
        find "$dir" -maxdepth 1 -name '*.jsonl' -printf '%T@ %f\n' | sort -rn | while read -r _ f; do
          printf '%s\t%s\t%s\n' "''${f%.jsonl}" "$(date -r "$dir/$f" '+%F %R')" "$(jq -rs "$title" "$dir/$f")"
        done |
          fzf --delimiter='\t' --with-nth=2.. \
            --preview='jq -r "$preview" "$dir"/{1}.jsonl | tail -n 100' --preview-window=wrap,follow |
          cut -f1
      }

      sid=''${2:-$(pick)}
      src=("$dir/$sid.jsonl")
      [[ -d $dir/$sid ]] && src+=("$dir/$sid")
      rsync -a --mkpath "''${src[@]}" "$host:$dir/"
      # shellcheck disable=SC2029 # $dir is the same on both hosts
      jq -cs --arg from "$HOSTNAME" --arg to "$host" --arg uuid "$(cat /proc/sys/kernel/random/uuid)" '
        map(select(.uuid and (.isSidechain | not))) | last
        | {parentUuid: .uuid, isSidechain, type: "user", uuid: $uuid, timestamp: (now | todate),
          userType, entrypoint, cwd, sessionId, version, gitBranch,
          message: {role: "user", content: "[automated note from claude-teleport] This session was moved from \($from) to \($to); files outside the project (e.g. the scratchpad) and background processes from before the move are gone."}}
      ' "$dir/$sid.jsonl" | ssh "$host" "cat >> '$dir/$sid.jsonl'"
      echo "teleported $sid to $host:$PWD"
    '';
  };
in
{
  xdg.configFile = {
    "claude/CLAUDE.md".text = agents.instructions.claude;
  }
  // agents.mkCommandFiles "claude/commands";
  home = {
    sessionVariables = {
      CLAUDE_CONFIG_DIR = cfgDir;
    };
    packages =
      let
        mkWrapper =
          overrides:
          config.lib.agents.mkPackages (
            {
              agentDir = "claude";
              package = pkgs.claude-code;
              args = [ "--dangerously-skip-permissions" ];
              extraRwDirs = [ config.home.sessionVariables.CODEX_HOME ];
            }
            // overrides
          );
        wrapperOverrides = {
          claude = {
            env = {
              # CLAUDE_CODE_AUTO_COMPACT_WINDOW = 400000;
              # CLAUDE_AUTOCOMPACT_PCT_OVERRIDE = 100;
            };
          };
          claude-oauth = {
            tokens = t: {
              CLAUDE_CODE_OAUTH_TOKEN = t.claudecode;
            };
          };
          claude-zai = {
            tokens = t: {
              ANTHROPIC_AUTH_TOKEN = t.zai;
            };
            env = {
              ANTHROPIC_BASE_URL = "https://api.z.ai/api/anthropic";
              API_TIMEOUT_MS = "3000000";
            };
          };
        };
      in
      lib.mapAttrsToList (
        wrapperName: overrides: mkWrapper (overrides // { inherit wrapperName; })
      ) wrapperOverrides
      ++ [
        pkgs.claude-desktop
        teleport
      ];
    activation = {
      claudeSettings = config.lib.home.json.set {
        showThinkingSummaries = true;
        tui = "fullscreen";
        enabledPlugins = {
          "rust-analyzer-lsp@claude-plugins-official" = false;
          "pyright-lsp@claude-plugins-official" = false;
        };
        includeCoAuthoredBy = false;
        switchModelsOnFlag = false;
        preferredNotifChannel = "notifications_disabled"; # replaced by the notify hooks
        remoteControlAtStartup = false;
        showClearContextOnPlanAccept = true;
        disableAutoMode = "disable";
        disableAgentView = true;
        voice = {
          enabled = false;
          mode = "tap";
        };
        inherit
          hooks
          permissions
          statusLine
          ;
      } "${cfgDir}/settings.json";
      claudeMcp = config.lib.home.json.set {
        mcpServers = {
        };
      } "${cfgDir}/.claude.json";
    };
  };
}
