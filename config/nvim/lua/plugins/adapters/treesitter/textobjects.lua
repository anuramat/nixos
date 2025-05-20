local ai = {
  'echasnovski/mini.ai',
  keys = {
    { 'a', mode = { 'x', 'o' } },
    { 'i', mode = { 'x', 'o' } },
  },
  dependencies = { 'nvim-treesitter-textobjects' },
  opts = function()
    local ts = require('mini.ai').gen_spec.treesitter
    return {
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
    }
  end,
}

local cfg = {
  swap = {
    enable = true,
    swap_next = {
      ['<a-l>'] = {
        query = { '@parameter.inner' },
        desc = 'swap with the next parameter',
      },
      -- doesn't properly work, no idempotency (eats whitespace)
      -- ['<a-j>'] = {
      --   query = { '@block.outer' },
      --   desc = 'swap with the block below',
      -- },
    },
    swap_previous = {
      ['<a-h>'] = {
        query = { '@parameter.inner' },
        desc = 'swap with the previous parameter',
      },
      -- doesn't properly work, no idempotency (eats whitespace)
      -- ['<a-k>'] = {
      --   query = { '@block.outer' },
      --   desc = 'swap with the block above',
      -- },
    },
  },
}

return { ai = ai, cfg = cfg }
