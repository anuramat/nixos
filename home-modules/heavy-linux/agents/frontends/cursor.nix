# WARNING: no global context file support yet; probably reads both CLAUDE and AGENTS, beware
{
  pkgs,
  ...
}:
{
  home = {
    packages = [
      pkgs.cursor-agent
    ];
  };
}
