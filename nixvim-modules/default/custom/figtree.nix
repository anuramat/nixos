{ pkgs, ... }:
{
  extraPlugins = [
    pkgs.vimPlugins.figtree-nvim
  ];
  extraConfigLua = ''
    require("figtree").setup({})
  '';
}
