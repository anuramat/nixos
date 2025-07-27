{
  lib,
  hax,
  config,
  pkgs,
  ...
}:
let
  inherit (config.lib) agents;
  inherit (lib) getExe;
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
  env = {
    ${agents.varNames.agentName} = name;
  };

  mkTemplates =
    dirName: templates:
    let
      root = ".claude/${dirName}";
    in
    lib.mapAttrs' (cmdName: prompt: {
      name = "${root}/${cmdName}.md";
      value = {
        text = prompt;
      };
    }) templates;

  commands = mkTemplates "commands" agents.prompts;
  subagents = mkTemplates "agents" agents.subagents;
in
{
  home = {
    file = (
      {
        ".claude/CLAUDE.md".text = agents.systemPrompt;
        ".claude/settings.json".text = lib.generators.toJSON { } {
          includeCoAuthoredBy = false;
          inherit hooks env permissions;
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
        args = "--dangerously-skip-permission";
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
