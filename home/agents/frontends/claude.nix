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
    # PostToolUse = [
    #   {
    #     hooks = [
    #       {
    #         command = "treefmt &>/dev/null || true";
    #         type = "command";
    #       }
    #     ];
    #     matcher = "Edit|MultiEdit|Write";
    #   }
    # ];
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
      pkgs.claude-desktop
      pkgs.ccusage
      cld
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
