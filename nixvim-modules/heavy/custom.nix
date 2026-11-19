{ pkgs, ... }:
{
  extraPlugins = [
    pkgs.vimPlugins.wastebin-nvim
    pkgs.vimPlugins.tree-climber-rust-nvim
    pkgs.vimPlugins.figtree-nvim
  ];
  extraConfigLua = ''
    function _G.wastebin_open(url)
      vim.fn.setreg("+", url)
      vim.ui.open(url)
    end
    require("wastebin").setup({
      url = "https://bin.ctrl.sn",
      -- the plugin runs `open_cmd .. " " .. url` as a shell job; call back into this nvim,
      -- whose clipboard provider and vim.ui.open pick the platform's tools
      open_cmd = "__wastebin() { " .. vim.fn.shellescape(vim.v.progpath)
        .. [[ --server "$NVIM" --remote-expr "v:lua.wastebin_open('$1')"; }; __wastebin]],
      ask = false,
    })

    require("figtree").setup({})
  '';
}
