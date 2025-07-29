{
  lib,
  hax,
  config,
  pkgs,
  ...
}:
let
  inherit (config.lib) agents;
  name = "Claude";
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
in
{
  home = {
    file = (
      {
        ".claude/CLAUDE.md".text = agents.systemPrompt;
        ".claude/settings.json".text = lib.generators.toJSON { } {
          includeCoAuthoredBy = false;
          inherit hooks permissions;
        };
      }
      // commands
      // subagents
    );
    packages = [
      (config.lib.agents.mkSandbox {
        wrapperName = "cld";
        agentName = name;
        package = pkgs.claude-code;
        args = "--dangerously-skip-permissions";
        agentDir = null;
        extraRwDirs = [
          "$HOME/.claude.json"
          "$HOME/.claude"
        ];
      })
    ];
    activation =
      let
        home = config.home.homeDirectory;
      in
      {
        claudeMcp = lib.hm.dag.entryAfter [ "writeBoundary" ] (
          hax.common.jsonUpdate pkgs "${home}/.claude.json" [
            {
              prop = ".mcpServers";
              file = config.lib.agents.mcp.json.filepath;
            }
          ]
        );
      };
  };
}
