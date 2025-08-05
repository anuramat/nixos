# configured: 2025-08-04
# TODO refactor
{
  lib,
  osConfig,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) mapAttrs;
  inherit (config.lib) agents;
  hooks = {
    Notification = [
      {
        hooks = [
          {
            command = ''notify-send "Claude Code" "$(jq .message -r)"'';
            type = "command";
          }
        ];
        matcher = "";
      }
    ];
    PostToolUse = [
      {
        hooks = [
          {
            command = "treefmt &>/dev/null || true";
            type = "command";
          }
        ];
        matcher = "Edit|MultiEdit|Write";
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
    agents.mkPrompts ".claude/commands" adaptedCommands;

  roles =
    let
      # remove some of the tools
      readOnlyTools = "Glob, Grep, LS, ExitPlanMode, Read, NotebookRead, WebFetch, TodoWrite, WebSearch, ListMcpResourcesTool, ReadMcpResourceTool";
      adaptedRoles =
        agents.roles
        |> mapAttrs (
          n: v:
          v.withFM {
            inherit (v) name description;
            model = "inherit";
            tools = if v.readonly then readOnlyTools else null;
          }
        );
    in
    agents.mkPrompts ".claude/agents" adaptedRoles;

  sandboxCfg = {
    wrapperName = "cld";
    package = pkgs.claude-code;
    args = "--dangerously-skip-permissions";
    env = {
      CLAUDE_CODE_OAUTH_TOKEN = "$(cat '${osConfig.age.secrets.claudecode.path}')";
    };
    agentDir = null;
    extraRwDirs = [
      "$HOME/.claude.json"
      "$HOME/.claude"
    ];
  };
  cld = config.lib.agents.mkSandbox sandboxCfg;

  home = config.home.homeDirectory;

  mkMcpConfig = config.lib.home.json.set {
    mcpServers = { inherit (config.lib.agents.mcp.raw) github; };
  };

  cldcp = config.lib.agents.mkSandbox (
    sandboxCfg
    // {
      copilot = true;
      wrapperName = "cldcp";
      env = {
        ANTHROPIC_BASE_URL = "http://localhost:${config.lib.agents.api.port}";
        ANTHROPIC_AUTH_TOKEN = "dummy";
        ANTHROPIC_MODEL = "gpt-4.1";
        ANTHROPIC_SMALL_FAST_MODEL = "gpt-4.1";
      };
    }
  );

in
{
  home = {
    file = (
      {
        ".claude/CLAUDE.md".text = agents.instructions.text;
      }
      // commands
      // roles
    );
    packages = [
      pkgs.claude-code
      cld
      cldcp
    ];
    activation = {
      claudeSettings = config.lib.home.json.set {
        includeCoAuthoredBy = false;
        inherit hooks permissions;
      } "${home}/.claude/settings.json";
      # claudeMcp = mkMcpConfig "${home}/.claude.json";
      claudeDesktopMcp = mkMcpConfig "${config.xdg.configHome}/Claude/claude_desktop_config.json";
    };
  };
}
