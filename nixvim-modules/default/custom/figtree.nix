{ pkgs, inputs, ... }:
{
  extraPlugins = [
    inputs.figtree.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
  extraConfigLua = ''
    require("figtree").setup({})
  '';
}
