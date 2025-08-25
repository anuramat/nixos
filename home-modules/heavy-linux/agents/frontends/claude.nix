# configured: 2025-08-04
# TODO refactor
{
  lib,
  config,
  pkgs,
  ...
}@args:
let
  inherit (lib) mapAttrs stringToCharacters concatStringsSep;
  inherit (config.lib) agents;
  statusLine = {
    type = "command";
    command =
      let
        script = ''
          input=$(cat)
          MODEL_DISPLAY=$(echo "$input" | jq -r '.model.display_name')

          starship module directory
          starship module git_branch
          starship module git_state
          starship module git_status
          echo " $MODEL_DISPLAY"

          # {
          #   "hook_event_name": "Status",
          #   "session_id": "abc123...",
          #   "transcript_path": "/path/to/transcript.json",
          #   "cwd": "/current/working/directory",
          #   "model": {
          #     "id": "claude-opus-4-1",
          #     "display_name": "Opus"
          #   },
          #   "workspace": {
          #     "current_dir": "/current/working/directory",
          #     "project_dir": "/original/project/directory"
          #   },
          #   "version": "1.0.80",
          #   "output_style": {
          #     "name": "default"
          #   }
          # }
        '';
      in
      pkgs.writeShellScript "statusline.sh" script;
    padding = 0;
  };
  hooks = {
    Notification = [
      {
        hooks = [
          {
            command = ''notify-send -a claude "Claude Code" "$(jq .message -r)"'';
            type = "command";
          }
        ];
        matcher = "";
      }
    ];
    PreCompact = [
      {
        hooks = [
          {
            command = "treefmt &>/dev/null || true";
            type = "command";
          }
        ];
        matcher = "manual|auto";
      }
    ];
  };
  permissions = {
    allow = [ ];
    deny = [ ];
  };

  commands =
    let
      adaptedCommands = agents.commands |> mapAttrs (n: v: v.withFM { inherit (v) description; });
    in
    agents.mkPrompts "claude/commands" adaptedCommands;

  roles =
    let
      toolsetParts = {
        i = "WebFetch, WebSearch";
        # TODO split junior into two, r and rwx

        r = "Glob, Grep, LS, Read, TodoWrite";
        w = "Edit, MultiEdit, Write, NotebookEdit";
        x = "Bash, KillBash, BashOutput, mcp__modagent__junior";
      };
      adaptedRoles =
        agents.roles
        |> mapAttrs (
          n: v:
          v.withFM {
            inherit (v) name description;
            # model = "inherit"; # TODO set per-role model smart/dumb/inherit
            tools =
              if v.toolset == null then
                null
              else
                stringToCharacters v.toolset |> map (x: toolsetParts.${x}) |> concatStringsSep ", ";
          }
        );
    in
    agents.mkPrompts "claude/agents" adaptedRoles;

  claudeWrapped =
    # turn on when this is fixed: https://github.com/anthropics/claude-code/issues/4085
    if false then
      config.lib.home.agenixWrapPkg pkgs.claude-code (t: {
        CLAUDE_CODE_OAUTH_TOKEN = t.claude-code;
      })
    else
      pkgs.claude-code;

  claudeBoxed = config.lib.agents.mkSandbox {
    wrapperName = "cld";
    package = claudeWrapped;
    args = "--dangerously-skip-permissions";
  };

  cfgDir = config.xdg.configHome + "/claude";
in
{
  xdg.configFile = (
    {
      "claude/CLAUDE.md".text = agents.instructions.text;
    }
    // commands
    // roles
  );
  home = {
    sessionVariables = {
      CLAUDE_CONFIG_DIR = cfgDir;
    };
    packages = [
      claudeWrapped
      claudeBoxed
      pkgs.claude-desktop
      pkgs.ccusage
    ];
    activation = {
      claudeSettings = config.lib.home.json.set {
        includeCoAuthoredBy = false;
        inherit
          hooks
          permissions
          statusLine
          ;
      } "${cfgDir}/settings.json";
      claudeMcp = config.lib.home.json.set {
        mcpServers = {
          # inherit (config.lib.agents.mcp.raw) modagent;
        };
      } "${cfgDir}/.claude.json";
      claudeDesktopMcp = config.lib.home.json.set {
        mcpServers = { inherit (config.lib.agents.mcp.raw) github; };
      } "${config.xdg.configHome}/Claude/claude_desktop_config.json";
    };
  };
}
