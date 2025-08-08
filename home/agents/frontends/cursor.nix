# TODO refactor
{
  config,
  osConfig,
  pkgs,
  ...
}:
{
  home = {
    packages = [
      pkgs.cursor-index
    ];
  };
}
