{
  pkgs,
  config,
  ...
}:
{
  home.packages = [
    pkgs.forge
  ];
}
