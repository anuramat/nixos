{ pkgs, inputs, ... }:
{
  extraPlugins = [
    inputs.figtree.packages.${pkgs.system}.default
  ];
  extraConfigLua = ''
    require("figtree").setup({})
  '';
}
