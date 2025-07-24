{ pkgs, ... }:
{
  home.packages = [
    (hax.agents.mkSandbox {
      inherit pkgs;
      pname = "gse";
      agentName = name;
      cmd = "${lib.getExe pkgs.claude-code}";
      extraRwDirs = [
        "$XDG_CONFIG_HOME/goose"
        "$XDG_STATE_HOME/goose"
      ];
    })
  ];
}
