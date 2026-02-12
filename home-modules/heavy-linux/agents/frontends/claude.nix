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
  };
  permissions = {
    allow = [ ];
    deny = [ ];
  };

  commands =
    let
      adaptedCommands = agents.commands |> mapAttrs (_: v: v.withFM { inherit (v) description; });
    in
    agents.mkPrompts "claude/commands" adaptedCommands;

  cfgDir = config.xdg.configHome + "/claude";
in
{
  xdg.configFile = {
    "claude/CLAUDE.md".text = agents.instructions.claude;
  }
  // commands;
  home = {
    sessionVariables = {
      CLAUDE_CONFIG_DIR = cfgDir;
    };
    packages =
      let
        mkClaude =
          overrides:
          config.lib.agents.mkPackages (
            {
              agentDir = "claude";
              package = pkgs.claude-code;
              args = [ "--dangerously-skip-permissions" ];
            }
            // overrides
          );
        claude = mkClaude {
          wrapperName = "claude";
          tokens = t: {
            CLAUDE_CODE_OAUTH_TOKEN = t.claudecode;
          };
        };
        claude-lite = mkClaude {
          wrapperName = "claude-lite";
          env =
            let
              gpt = "github_copilot/gpt-5-mini";
              glm = "cerebras/zai-glm-4.7";
            in
            {
              ANTHROPIC_AUTH_TOKEN = "dummy";
              ANTHROPIC_DEFAULT_OPUS_MODEL = gpt;
              ANTHROPIC_DEFAULT_SONNET_MODEL = glm;
              ANTHROPIC_DEFAULT_HAIKU_MODEL = glm;
              CLAUDE_CODE_SUBAGENT_MODEL = glm;
              ANTHROPIC_BASE_URL = "http://localhost:11333";
            };
        };
        claude-zai = mkClaude {
          wrapperName = "claude-zai";
          tokens = t: {
            ANTHROPIC_AUTH_TOKEN = t.zai;
          };
          env = {
            ANTHROPIC_BASE_URL = "https://api.z.ai/api/anthropic";
          };
        };

      in

      [
        claude
        claude-zai
        claude-lite
      ]
      ++ (with pkgs; [
        ccusage
        ccusage-codex
        claude-monitor
      ]);
    activation = {
      claudeSettings = config.lib.home.json.set {
        includeCoAuthoredBy = false;
        env = {
          # CLAUDE_CODE_DISABLE_TERMINAL_TITLE = 1;
          # DISABLE_NON_ESSENTIAL_MODEL_CALLS = 1;
          # MAX_MCP_OUTPUT_TOKENS -- default 25k
          # BASH_MAX_OUTPUT_LENGTH -- chars, default 30k
        };
        inherit
          hooks
          permissions
          statusLine
          ;
      } "${cfgDir}/settings.json";
      claudeMcp = config.lib.home.json.set {
        mcpServers = {
          # inherit (config.lib.agents.mcp.raw) ddg;
        };
      } "${cfgDir}/.claude.json";
    };
  };
}
