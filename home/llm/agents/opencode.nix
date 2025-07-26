{
  pkgs,
  hax,
  lib,
  config,
  ...
}:
let
  name = "opencode";
  settings = {
    instructions = [
      "CLAUDE.md"
    ];
  };
  xdgSubdir = "opencode";
in
{
  home.packages = [
    (config.lib.agents.mkSandbox {
      inherit pkgs;
      pname = "opencode-sandboxed";
      agentName = name;
      cmd = "${lib.getExe pkgs.opencode}";
      inherit xdgSubdir;
    })
  ];

  activation = {
    opencodeConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] (
      hax.common.jsonUpdate pkgs [
        {
          prop = ".";
          target = "${config.xdg.configHome}/${xdgSubdir}/opencode.json";
          text = lib.generators.toJSON { } settings;
        }
      ]
    );
  };
}
