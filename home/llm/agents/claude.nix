{
  lib,
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
  lib.test = "x";
  home.file = (
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
  home.packages = [
    (config.lib.agents.mkSandbox {
      inherit pkgs;
      pname = "cld";
      agentName = name;
      cmd = "${lib.getExe pkgs.claude-code} --dangerously-skip-permissions";
      extraRwDirs = [
        "$XDG_CONFIG_HOME/claude"
        "$HOME/.claude.json"
        "$HOME/.claude"
      ];
    })
  ];
}
