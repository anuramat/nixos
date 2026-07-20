{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.lib) agents;

  ompHome = config.xdg.configHome + "/omp";
  env.PI_CODING_AGENT_DIR = ompHome;
  commands =
    agents.commands
    |> lib.mapAttrs (_: v: v.withFM { inherit (v) description; })
    |> agents.mkPrompts "omp/commands";
  omp = agents.mkPackages {
    binName = "omp";
    package = pkgs.oh-my-pi;
    args = [ "--yolo" ];
    inherit env;
    agentDir = null;
    extraRwDirs = [ ompHome ];
  };
in
{
  xdg.configFile = {
    "omp/AGENTS.md".text = agents.instructions.omp;
  }
  // commands;

  home = {
    sessionVariables = env;
    packages = [ omp ];
    activation = {
      ompSettings = config.lib.home.yaml.set {
        startup.checkUpdate = false;
      } "${ompHome}/config.yml";
    };
  };
}
