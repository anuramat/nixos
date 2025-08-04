{
  inputs,
  pkgs,
  ...
}:
{
  extraPlugins = [
    inputs.mcphub.packages.${pkgs.system}.default
  ];
}
