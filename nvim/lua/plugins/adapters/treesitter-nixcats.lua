-- vim: fdl=3

-- Treesitter textobjects (mini.ai)
local textobjects = {
  'mini.ai',
  keys = {
    { 'a', mode = { 'x', 'o' } },
    { 'i', mode = { 'x', 'o' } },
  },
  after = function()
    local ai = require('mini.ai')
    local ts = ai.gen_spec.treesitter
    ai.setup({
      n_lines = 500,
      custom_textobjects = {
        -- b = false, -- = ([{
        q = false, -- = `'"
        -- functions
        F = ts({
          a = { '@function.outer' }, -- entire declaration
          i = { '@function.inner' }, -- body
        }, {}),
        f = ts({
          a = { '@call.outer' }, -- line with the call
          i = { '@call.inner' }, -- arguments
        }),
        a = ts({
          a = { '@parameter.outer' }, -- with comma
          i = { '@parameter.inner' }, -- only parameter itself
        }),
        -- there are not really used
        e = ts({
          a = { '@assignment.outer' }, -- entire assigment line
          i = { '@assignment.rhs' }, -- only the rhs
        }),
        r = ts({
          a = { '@return.outer' }, -- entire return line
          i = { '@return.inner' }, -- only the return value
        }),
        -- ~~~~~~~~~~~~~~~~~~~~~ misc ~~~~~~~~~~~~~~~~~~~~~~ --
        b = ts({ -- code blocks in markdown (custom query)
          a = { '@code_block.outer' },
          i = { '@code_block.inner' },
        }),
        s = ts({ -- structs/classes; instance/definition
          a = { '@class.outer' },
          i = { '@class.inner' },
        }, {}),
        c = ts({ -- inner doesn't work with most languages, use outer
          a = { '@comment.outer' },
          i = { '@comment.inner' },
        }),
        o = ts({ -- any other blocks
          -- not sure if all of these make sense even
          -- TODO find a reference
          a = { '@block.outer', '@conditional.outer', '@loop.outer', '@frame.outer' },
          i = { '@block.inner', '@conditional.inner', '@loop.inner', '@frame.inner' },
        }, {}),
      },
      silent = true,
    })
  end,
}

-- BUG E490: no fold found <https://github.com/neovim/neovim/issues/28692>
return {
  textobjects,
  {
    'nvim-treesitter',
    event = 'VeryLazy',
    after = function()
      require('nvim-treesitter-textobjects').setup({})
      require('nvim-treesitter-context').setup({
        enable = true,
        max_lines = 1, -- How many lines the window should span. Values <= 0 mean no limit.
        min_window_height = 20, -- Minimum editor window height to enable context. Values <= 0 mean no limit.
        line_numbers = true,
        multiline_threshold = 1, -- Maximum number of lines to show for a single context
        trim_scope = 'outer', -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
        mode = 'cursor', -- Line used to calculate context. Choices: 'cursor', 'topline'
        -- separator = '―', -- Separator between context and content. nil or a single character
        zindex = 20, -- The Z-index of the context window
      })

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
