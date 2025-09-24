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
      adaptedCommands = agents.commands |> mapAttrs (n: v: v.withFM { inherit (v) description; });
    in
    agents.mkPrompts "claude/commands" adaptedCommands;

  roles =
    let
      adaptedRoles =
        agents.roles
        |> mapAttrs (
          n: v:
          v.withFM {
            inherit (v) name description;
            model = "inherit"; # TODO
          }
        );
    in
    agents.mkPrompts "claude/agents" adaptedRoles;

  litePkg = config.lib.agents.mkPackages {
    agentDir = "claude";
    package = pkgs.claude-code;
    args = [ "--dangerously-skip-permissions" ];
    wrapperName = "claude-lite";
    tokens = t: {
      ANTHROPIC_AUTH_TOKEN = t.zai;
    };
    env = {
      ANTHROPIC_DEFAULT_OPUS_MODEL = "github_copilot/gpt-5-mini";
      ANTHROPIC_DEFAULT_SONNET_MODEL = "cerebras/qwen-3-coder-480b";
      ANTHROPIC_MODEL = "opusplan";
      ANTHROPIC_SMALL_FAST_MODEL = "github_copilot/gpt-4.1";
      ANTHROPIC_BASE_URL = "http://localhost:11333";
    };
  };

  zaiPkg = config.lib.agents.mkPackages {
    agentDir = "claude";
    package = pkgs.claude-code;
    args = [ "--dangerously-skip-permissions" ];
    wrapperName = "claude-zai";
    tokens = t: {
      ANTHROPIC_AUTH_TOKEN = t.zai;
    };
    env = {
      ANTHROPIC_MODEL = "glm-4.5";
      ANTHROPIC_SMALL_FAST_MODEL = "glm-4.5-air";
      ANTHROPIC_BASE_URL = "https://api.z.ai/api/anthropic";
    };
  };
  pkg = config.lib.agents.mkPackages {
    agentDir = "claude";
    package = pkgs.claude-code;
    args = [ "--dangerously-skip-permissions" ];
    wrapperName = "cld";
    tokens = t: {
      # broken: https://github.com/anthropics/claude-code/issues/4085
      CLAUDE_CODE_OAUTH_TOKEN = t.claude;
    };
  };

  cfgDir = config.xdg.configHome + "/claude";
in
{
  xdg.configFile = (
    {
      "claude/CLAUDE.md".text = agents.instructions.claude;
    }
    // commands
    // roles
  );
  home = {
    sessionVariables = {
      CLAUDE_CONFIG_DIR = cfgDir;
    };
    packages = [
      pkg
      zaiPkg
      litePkg
      pkgs.claude-desktop
      pkgs.ccusage
      pkgs.claude-monitor
    ];
    activation = {
      claudeSettings = config.lib.home.json.set {
        includeCoAuthoredBy = false;
        env = {
          CLAUDE_CODE_DISABLE_TERMINAL_TITLE = 1;
          DISABLE_NON_ESSENTIAL_MODEL_CALLS = 1;
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
          inherit (config.lib.agents.mcp.raw) ddg deepwiki;
        };
      } "${cfgDir}/.claude.json";
      claudeDesktopMcp = config.lib.home.json.set {
        mcpServers = { };
      } "${config.xdg.configHome}/Claude/claude_desktop_config.json";
    };
  };
}
