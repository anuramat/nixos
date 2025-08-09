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
