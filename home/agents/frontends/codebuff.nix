{
  pkgs,
  config,
  ...
}:
{
  home.packages = [
    pkgs.codebuff
  ];
}
