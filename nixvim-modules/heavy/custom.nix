{ pkgs, ... }:
{
  extraPlugins = [
    pkgs.vimPlugins.wastebin-nvim
    pkgs.vimPlugins.tree-climber-rust-nvim
    pkgs.vimPlugins.figtree-nvim
  ];
  extraConfigLua = ''
    require("wastebin").setup({
      url = "https://bin.ctrl.sn",
      open_cmd = '__wastebin() { wl-copy "$1" && xdg-open "$1"; }; __wastebin',
      ask = false,
    })

    require("figtree").setup({})
  '';
}
