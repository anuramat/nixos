return {
  {
    -- uses cscope/gtags-cscope
    'dhananjaylatkar/cscope_maps.nvim',
    dependencies = {
      'ibhagwan/fzf-lua',
    },
    opts = {},
  },
  {
    -- regenerates tag files
    'ludovicchabant/vim-gutentags',
    init = function()
      vim.g.gutentags_modules = { 'cscope_maps' } -- This is required. Other config is optional
      vim.g.gutentags_cscope_build_inverted_index_maps = 1
      vim.g.gutentags_cache_dir = vim.fn.expand('$XDG_CACHE_HOME/gutentags')
      vim.g.gutentags_file_list_command = 'fd -e c -e h'
      -- vim.g.gutentags_trace = 1
    end,
  },
}
-- https://github.com/skywind3000/gutentags_plus
-- gtags for gutentags
-- AFAIU uses gtags-cscope
-- so shouldn't be needed given that we have a cscope_maps.nvim
