local u = require('utils.helpers')

return {
  'ibhagwan/fzf-lua',
  -- optional for icon support
  dependencies = {
    'nvim-tree/nvim-web-devicons',
  },
  event = 'VeryLazy',
  opts = {},
  keys = u.wrap_lazy_keys('<leader>f', {
    -- :he fzf-lua-commands

    { 'o', 'files' },
    { 'O', 'oldfiles' },
    { 'a', 'args' },
    { 'b', 'buffers' },
    { 'm', 'marks' },

    { '/', 'curbuf' },
    { 'g', 'live_grep' },
    { 'G', 'grep_last' },
    -- { 'G', 'grep' }, -- useful on large projects

    { 'd', 'diagnostics_document' },
    { 'D', 'diagnostics_workspace' },
    { 's', 'lsp_document_symbols' },
    { 'S', 'lsp_workspace_symbols' },
    { 't', 'treesitter' },

    { 'r', 'resume' },
    { 'h', 'helptags' },
    { 'k', 'keymaps' },
    { 'p', 'builtin' },
  }, 'fuzzy: ', 'FzfLua '),
}

--     { 'G', '<cmd>Telescope live_grep_args<cr>', desc = 'Live Grep' },
--     { 'S', '<cmd>Telescope lsp_dynamic_workspace_symbols<cr>', desc = 'Dynamic Workspace Symbols' },
--     { 'b', '<cmd>Telescope buffers<cr>', desc = 'Buffers' },
--     { 'd', '<cmd>Telescope diagnostics<cr>', desc = 'Workspace Diagnostics' },
--     { 'g', '<cmd>Telescope live_grep<cr>', desc = 'Live Grep' },
--     { 'h', '<cmd>Telescope harpoon marks<cr>', desc = 'Harpoons' },
--     { 'j', '<cmd>Telescope zoxide list<cr>', desc = 'Zoxide' },
--     { 'm', '<cmd>Telescope marks<cr>', desc = 'Marks' },
--     { 'o', '<cmd>Telescope find_files<cr>', desc = 'Files' },
--     { 'p', '<cmd>Telescope builtin<cr>', desc = 'Pickers' },
--     { 'q', '<cmd>Telescope quickfix<cr>', desc = 'Quickfix' },
--     { 'Q', '<cmd>Telescope quickfixhistory<cr>', desc = 'Quickfix history' },
--     { 'r', '<cmd>Telescope lsp_references<cr>', desc = 'References' },
--     { 's', '<cmd>Telescope lsp_document_symbols<cr>', desc = 'Document Symbols' },
