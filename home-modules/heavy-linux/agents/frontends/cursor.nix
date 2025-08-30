# WARNING: no global context file support yet; probably reads both CLAUDE and AGENTS, beware
{
  pkgs,
  config,
  ...
}:
{
  home = {
    packages = [
      pkgs.cursor-agent
      (config.lib.agents.mkSandbox {
        wrapperName = "csa";
        package = pkgs.cursor-agent;
        agentDir = "cursor";
      })
    ];
  };
}
