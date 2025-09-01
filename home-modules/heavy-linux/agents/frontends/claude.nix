# should be concise as possible
# maybe bring back roles.nix
# NOTE: only reads CLAUDE.md
{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) mapAttrs;
  inherit (config.lib) agents;
  statusLine = {
    type = "command";
    command =
      let
        script = ''
          input=$(cat)
          model_display=$(echo "$input" | jq -r '.model.display_name')
          output_style=$(echo "$input" | jq -r '.output_style.name')
          # TODO output_style.name

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
  hooks = {
    Notification = [
      {
        hooks = [
          {
            command = # bash
              ''notify-send -a claude "Claude Code" "$(jq .message -r)"'';
            type = "command";
          }
        ];
        matcher = "";
      }
    ];
    Stop = [
      {
        hooks = [
          {
            command = # bash
              let
                script = pkgs.writeShellScript "reminders" ''
                  if [[ -n "$(git status --porcelain)" ]]; then
                    echo "automated reminder: repository is dirty -- if appropriate, consider updating CLAUDE.md, running formatters, and making a git commit" >&2
                    exit 2
                  fi
                '';
              in
              ''if [ $(jq .stop_hook_active -r) = true ]; then exit 0; fi; ${script}'';
            type = "command";
          }
        ];
        matcher = "";
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
      "claude/CLAUDE.md".text = agents.instructions.claude;
    }
    // commands
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
        env = {
          MAX_THINKING_TOKENS = 1024;
          CLAUDE_CODE_DISABLE_TERMINAL_TITLE = 1;
          # DISABLE_NON_ESSENTIAL_MODEL_CALLS (1 for disable)
          # MAX_MCP_OUTPUT_TOKENS default 25k
          # BASH_MAX_OUTPUT_LENGTH default 30k chars
        };
        inherit
          hooks
          permissions
          statusLine
          ;
      } "${cfgDir}/settings.json";
      claudeMcp = config.lib.home.json.set {
        mcpServers = {
          # inherit (config.lib.agents.mcp.raw) ...;
        };
      } "${cfgDir}/.claude.json";
      claudeDesktopMcp = config.lib.home.json.set {
        mcpServers = { inherit (config.lib.agents.mcp.raw) github; };
      } "${config.xdg.configHome}/Claude/claude_desktop_config.json";
    };
  };
}
# MAX_THINKING_TOKENS=1024
