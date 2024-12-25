local u = require('utils.helpers')

return {
  'nvim-telescope/telescope.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-treesitter/nvim-treesitter',
    'jvgrootveld/telescope-zoxide',
    'nvim-telescope/telescope-symbols.nvim',
    {
      'nvim-telescope/telescope-fzf-native.nvim',
      build = 'make',
    },
    {
      'nvim-telescope/telescope-live-grep-args.nvim',
    },
  },
  keys = u.lazy_prefix('<leader>f', {
    { 'G', '<cmd>Telescope live_grep_args<cr>', desc = 'Live Grep' },
    { 'S', '<cmd>Telescope lsp_dynamic_workspace_symbols<cr>', desc = 'Dynamic Workspace Symbols' },
    { 'b', '<cmd>Telescope buffers<cr>', desc = 'Buffers' },
    { 'd', '<cmd>Telescope diagnostics<cr>', desc = 'Workspace Diagnostics' },
    { 'g', '<cmd>Telescope live_grep<cr>', desc = 'Live Grep' },
    { 'h', '<cmd>Telescope harpoon marks<cr>', desc = 'Harpoons' },
    { 'j', '<cmd>Telescope zoxide list<cr>', desc = 'Zoxide' },
    { 'm', '<cmd>Telescope marks<cr>', desc = 'Marks' },
    { 'o', '<cmd>Telescope find_files<cr>', desc = 'Files' },
    { 'p', '<cmd>Telescope builtin<cr>', desc = 'Pickers' },
    { 'q', '<cmd>Telescope quickfix<cr>', desc = 'Quickfix' },
    { 'Q', '<cmd>Telescope quickfixhistory<cr>', desc = 'Quickfix history' },
    { 'r', '<cmd>Telescope lsp_references<cr>', desc = 'References' },
    { 's', '<cmd>Telescope lsp_document_symbols<cr>', desc = 'Document Symbols' },
  }, 'Tele'),
  opts = function()
    local t = require('telescope')
    t.load_extension('zoxide')
    t.load_extension('fzf')
    t.load_extension('live_grep_args')
    local opts = {
      defaults = {
        mappings = {
          i = { ['<c-j>'] = 'select_default' },
          n = { ['<c-j>'] = 'select_default' },
        },
        wrap_results = true,
        layout_config = {
          horizontal = {
            preview_width = 0.8,
            height = 999,
            preview_cutoff = 120,
            width = 999,
          },
        },
        prompt_prefix = ' ',
        selection_caret = ' ',
        multi_icon = ' ',
        path_display = { 'truncate' }, -- TODO report 'smart' breaks 'truncate'
        dynamic_preview_title = true,
        vimgrep_arguments = {
          'rg',
          '--color=never',
          '--no-heading',
          '--with-filename',
          '--line-number',
          '--column',
        },
      },
      pickers = {
        keymaps = { show_plug = false },
        colorscheme = { enable_preview = false },
        buffers = { sort_mru = true },
      },
    }
    if vim.g.border == 'solid' then
      -- TODO support other border values
      opts.defaults.borderchars = {
        prompt = { '' },
        results = { '' },
        preview = { '' },
      }
    end
    return opts
  end,
}
