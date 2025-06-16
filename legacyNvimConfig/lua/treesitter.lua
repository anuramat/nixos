-- vim: fdl=3

-- BUG E490: no fold found <https://github.com/neovim/neovim/issues/28692>
return {
  require('plugins.adapters.treesitter.textobjects'),
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    lazy = false,
    dependencies = {
      {
        -- TODO swaps are broken for now <https://github.com/nvim-treesitter/nvim-treesitter-textobjects/issues/772>
        -- incremental selection too
        'nvim-treesitter/nvim-treesitter-textobjects',
        branch = 'main',
        opts = {},
      },
    },
    config = function()
      vim.api.nvim_create_autocmd('FileType', {
        callback = function(ev)
          if vim.treesitter.language.add(ev.match) then
            vim.treesitter.start(ev.buf, ev.match) -- syntax highlighting, provided by Neovim
            vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
            vim.bo.indentexpr = 'v:lua.require\'nvim-treesitter\'.indentexpr()'
          end
        end,
      })
    end,
  },
}
