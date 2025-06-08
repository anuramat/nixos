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
      {
        'nvim-treesitter/nvim-treesitter-context',
        opts = {
          enable = true,
          max_lines = 1, -- How many lines the window should span. Values <= 0 mean no limit.
          min_window_height = 20, -- Minimum editor window height to enable context. Values <= 0 mean no limit.
          line_numbers = true,
          multiline_threshold = 1, -- Maximum number of lines to show for a single context
          trim_scope = 'outer', -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
          mode = 'cursor', -- Line used to calculate context. Choices: 'cursor', 'topline'
          -- separator = '―', -- Separator between context and content. nil or a single character
          zindex = 20, -- The Z-index of the context window
        },
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
