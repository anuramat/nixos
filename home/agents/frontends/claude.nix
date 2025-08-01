{
  lib,
  osConfig,
  config,
  pkgs,
  ...
}:
let
  inherit (config.lib) agents;
  hooks = {
    Notification = [
      {
        hooks = [
          {
            command = "jq .message -r | xargs -0I{} notify-send 'Claude Code' {}";
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

  commands = agents.mkPrompts ".claude/commands" agents.commands;
  subagents = agents.mkPrompts ".claude/agents" agents.roles;

  cld = config.lib.agents.mkSandbox {
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

  home = config.home.homeDirectory;

  mkMcpConfig = config.lib.home.jsonUpdate {
    ".mcpServers" = config.lib.agents.mcp.json.file;
  };
in
{
  home = {
    file = (
      {
        ".claude/CLAUDE.md".text = agents.instructions.text;
        ".claude/settings.json".text = lib.generators.toJSON { } {
          includeCoAuthoredBy = false;
          inherit hooks permissions;
        };
      }
      // commands
      // subagents
    );
    packages = [
      cld
    ];
    activation = {
      claudeMcp = mkMcpConfig "${home}/.claude.json";
      claudeDesktopMcp = mkMcpConfig "${config.xdg.configHome}/Claude/claude_desktop_config.json";
    };
  };
}
