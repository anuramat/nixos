{
  lib,
  hax,
  pkgs,
  ...
}:
let
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
  inherit (hax.agents) varNames;
  env = {
    ${varNames.agentName} = "Claude";
  };

  commands =
    let
      root = "./claude/commands";
    in
    lib.mapAttrs' (n: v: {
      name = "${root}/${name}.md";
      value = {
        text = v;
      };
    }) hax.agents.prompts;
in
{
  home.file = {
    ".claude/CLAUDE.md".text = hax.agents.system { inherit lib varNames; };
    ".claude/settings.json".text =
      lib.generators.toJSON { } {
        includeCoAuthoredBy = false;
        inherit hooks env permissions;
      }
      // commands;
  };
  home.packages = [
    (hax.agents.mkSandbox {
      pname = "cld";
      cmd = "${lib.getExe pkgs.claude-code} --dangerously-skip-permissions";
      extraRwDirs = [
        "$XDG_CONFIG_HOME/claude"
        "$HOME/.claude.json"
        "$HOME/.claude"
      ];
    })
  ];
}
