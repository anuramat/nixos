-- UI plugins configuration for nixcats + lze

return {
  -- Rainbow delimiters (loaded at startup since it's in treesitter category)

  -- Dressing.nvim
  {
    'dressing.nvim',
    after = function() require('dressing').setup({}) end,
  },

  -- Colorizer
  {
    'nvim-colorizer.lua',
    ft = { 'css', 'yaml' },
    after = function() require('colorizer').setup({}) end,
  },

  -- Todo comments
  {
    'todo-comments.nvim',
    after = function()
      require('todo-comments').setup({
        signs = false,
        highlight = {
          keyword = 'bg',
          pattern = [[<(KEYWORDS)>]],
          multiline = false,
        },
        search = {
          pattern = [[\b(KEYWORDS)\b]],
        },
      })
    end,
  },

  -- Lightbulb
  {
    'nvim-lightbulb',
    event = 'LspAttach',
    after = function()
      require('nvim-lightbulb').setup({
        autocmd = { enabled = true },
        ignore = {
          ft = { 'markdown' },
        },
      })
    end,
  },

  -- Figtree (loaded at startup since it has high priority)

  -- Fidget
  {
    'fidget.nvim',
    event = 'LspAttach',
    after = function() require('fidget').setup({}) end,
  },
}
