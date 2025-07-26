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
  name = "claude";
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
        inherit pkgs;
        pname = "cld";
        agentName = name;
        cmd = "${getExe pkgs.claude-code} --dangerously-skip-permissions";
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
          hax.common.jsonUpdate pkgs [
            {
              prop = ".mcpServers";
              target = "${home}/.claude.json";
              file = config.lib.agents.mcp.json.filepath;
            }
          ]
        );
      };
  };
}
