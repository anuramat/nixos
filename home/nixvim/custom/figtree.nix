{ pkgs, inputs, ... }:
{
  extraPlugins = [
    inputs.mdmath.packages.${pkgs.system}.default
  ];
  extraConfigLua = ''
    require("figtree").setup({})
  '';
}
