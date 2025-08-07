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
  inherit (lib) mapAttrs stringToCharacters concatStringsSep;
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
    agents.mkPrompts ".claude/commands" adaptedCommands;

  roles =
    let
      toolsetParts = {
        r = "Glob, Grep, LS, Read, TodoWrite, mcp__modagent__junior";
        i = "WebFetch, WebSearch";
        w = "Edit, MultiEdit, Write, NotebookEdit";
        x = "Bash";
      };
      adaptedRoles =
        agents.roles
        |> mapAttrs (
          n: v:
          v.withFM {
            inherit (v) name description;
            model = "inherit";
            tools =
              if v.toolset == null then
                null
              else
                stringToCharacters v.toolset |> map (x: toolsetParts.${x}) |> concatStringsSep ", ";
          }
        );
    in
    agents.mkPrompts ".claude/agents" adaptedRoles;

  claudeWrapped = config.lib.home.agenixWrap pkgs.claude-code {
    CLAUDE_CODE_OAUTH_TOKEN = osConfig.age.secrets.claudecode;
  };

  claudeBoxed = config.lib.agents.mkSandbox {
    wrapperName = "cld";
    package = claudeWrapped;
    args = "--dangerously-skip-permissions";
  };

  home = config.home.homeDirectory;

in
{
  home = {
    sessionVariables = {
      CLAUDE_CONFIG_DIR = config.xdg.configHome + "/claude";
    };
    file = (
      {
        ".claude/CLAUDE.md".text = agents.instructions.text;
      }
      // commands
      // roles
    );
    packages = [
      claudeWrapped
      claudeBoxed
      pkgs.claude-desktop
      pkgs.ccusage
    ];
    activation = {
      claudeSettings = config.lib.home.json.set {
        includeCoAuthoredBy = false;
        inherit hooks permissions;
      } "${home}/.claude/settings.json";
      claudeMcp = config.lib.home.json.set {
        mcpServers = {
          inherit (config.lib.agents.mcp.raw) modagent;
        };
      } "${home}/.claude.json";
      claudeDesktopMcp = config.lib.home.json.set {
        mcpServers = { inherit (config.lib.agents.mcp.raw) github; };
      } "${config.xdg.configHome}/Claude/claude_desktop_config.json";
    };
  };
}
