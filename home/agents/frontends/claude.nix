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

  commands =
    let
      adaptedCommands = agents.commands |> mapAttrs (n: v: v.withFM { inherit (v) description; });
    in
    agents.mkPrompts ".claude/commands" adaptedCommands;

  roles =
    let
      readOnlyTools = "Glob, Grep, LS, ExitPlanMode, Read, NotebookRead, WebFetch, TodoWrite, WebSearch, ListMcpResourcesTool, ReadMcpResourceTool";
      adaptedRoles =
        agents.roles
        |> mapAttrs (
          n: v:
          v.withFM {
            inherit (v) name description;
            tools = if v.readonly then readOnlyTools else null;
          }
        );
    in
    agents.mkPrompts ".claude/agents" adaptedRoles;

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

  mkMcpConfig = config.lib.home.json.set {
    mcpServers = config.lib.agents.mcp.file;
  };
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
      cld
    ];
    activation = {
      claudeSettings = config.lib.home.json.set {
        includeCoAuthoredBy = false;
        inherit hooks permissions;
      } "${home}/.claude/settings.json";
      claudeMcp = mkMcpConfig "${home}/.claude.json";
      claudeDesktopMcp = mkMcpConfig "${config.xdg.configHome}/Claude/claude_desktop_config.json";
    };
  };
}
