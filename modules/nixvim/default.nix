# hover.nvim
# nvim-genghis
# https://github.com/netmute/ctags-lsp.nvim
# https://github.com/netmute/ctags-lsp
# https://github.com/dhananjaylatkar/cscope_maps.nvim
# https://github.com/ludovicchabant/vim-gutentags
# https://github.com/danymat/neogen
# https://github.com/kristijanhusak/vim-dadbod-completion
# https://github.com/tpope/vim-dadbod
# https://github.com/kristijanhusak/vim-dadbod-ui
# https://github.com/nvim-neotest/neotest
# https://github.com/mattn/efm-langserver
{
  pkgs,
  inputs,
  ...
}:
{
  nixpkgs.overlays = [
    inputs.self.overlays.default
  ];
  imports = [
    ./filemgr.nix
    ./fzf.nix
    ./git.nix
    ./ide
    ./lang
    ./misc.nix
    ./treesitter.nix
    ./ui.nix
    ./vim.nix
    ./custom
    ./basic.nix
    ./ft.nix
  ];

  plugins.lz-n.enable = true;
  luaLoader.enable = true;
  performance = {
    combinePlugins = {
      enable = false;
      standalonePlugins = [
      ];
    };
    byteCompileLua = {
      enable = false;
      initLua = true;
      configs = true;
      plugins = true;
      nvimRuntime = true;
      luaLib = true;
    };
  };

  viAlias = false;
  vimAlias = false;
}
