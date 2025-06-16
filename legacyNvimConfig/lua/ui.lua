-- vim: fdl=1
local function transparent_bg() return false end -- TODO stylix
return {
  -- dressing.nvim -- vim.ui.select (choice menus), vim.ui.input (lsp rename)
  {
    'stevearc/dressing.nvim',
    opts = {},
    event = 'VeryLazy',
  },
  -- lightbulb - code action indicator
  {
    'kosayoda/nvim-lightbulb',
    event = 'LspAttach',
    branch = 'master', -- until 7c651c0185bfe712948f8c4e21eb3ca495e4faa5 gets merged in
    config = {
      autocmd = { enabled = true },
      ignore = {
        ft = { 'markdown' },
      },
    },
  },
  -- figlet based greeter
  {
    -- conflicts with fzf-lua for some reason
    'anuramat/figtree.nvim',
    enabled = false,
    priority = 999,
    lazy = false,
    dev = false,
    opts = {},
  },
}
