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

  commands =
    let
      root = "./claude/commands";
    in
    lib.mapAttrs' (cmdName: prompt: {
      name = "${root}/${cmdName}.md";
      value = {
        text = prompt;
      };
    }) (agents.prompts);
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
