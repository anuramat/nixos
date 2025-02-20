-- vim: fdl=1

local u = require('utils.helpers')

local function log_point(m) m.set_breakpoint(nil, nil, vim.fn.input('Log point message: ')) end

local lhs_prefix = '<leader>d'
return {
  -- nvim-dap
  {
    'mfussenegger/nvim-dap',
    dependencies = {
      {
        'theHamsta/nvim-dap-virtual-text',
        dependencies = 'nvim-treesitter/nvim-treesitter',
        opts = {},
      },
    },
    config = function()
      -- some of these are used in catppuccin
      local sign = vim.fn.sign_define
      sign('DapBreakpoint', { text = '', texthl = 'DapBreakpoint', linehl = '', numhl = '' })
      sign('DapBreakpointCondition', { text = 'C', texthl = 'DapBreakpointCondition', linehl = '', numhl = '' })
      sign('DapLogPoint', { text = 'L', texthl = 'DapLogPoint', linehl = '', numhl = '' })
      sign('DapStopped', { text = '→', texthl = 'DapStopped', linehl = '', numhl = '' })
      -- sign('DapBreakpointRejected', { text = 'R', texthl = 'DapBreakpointRejected', linehl = '', numhl = '' })
    end,
  -- stylua: ignore
  keys = u.wrap_lazy_keys( {
    { 'b', function(m) m.toggle_breakpoint() end,  'Toggle Breakpoint' },
    { 'c', function(m) m.continue() end,         'Continue' },
    { 'd', function(m) m.run_last() end,           'Run Last Debug Session' },
    { 'i', function(m) m.step_into() end,          'Step Into' },
    { 'l', log_point,                           'Set Log Point' },
    { 'n', function(m) m.step_over() end,          'Step Over' },
    { 'o', function(m) m.step_out() end,           'Step Out' },
    { 'r', function(m) m.repl.open() end,          'Open Debug REPL' },
  }, {
    module = 'dap',
    lhs_prefix =lhs_prefix ,
  } ),
  },
  -- nvim-dap-ui
  {
    'rcarriga/nvim-dap-ui',
    dependencies = { 'mfussenegger/nvim-dap', 'nvim-neotest/nvim-nio' },
  -- stylua: ignore
  keys = u.wrap_lazy_keys( {
    { "u", function(m) m.toggle() end, "Toggle Dap UI" },
    { "e", function(m) m.eval() end, "Evaluate", mode = {"n", "v"} },
  }, {
module = 'dapui',
        lhs_prefix=lhs_prefix
      }),
    opts = {
      -- setting up default settings explicitly just in case
      floating = {
        border = 'single',
        mappings = {
          close = { 'q', '<Esc>' },
        },
      },
      {
        edit = 'e',
        expand = { '<CR>', '<2-LeftMouse>' },
        open = 'o',
        remove = 'd',
        repl = 'r',
        toggle = 't',
      },
    },
  },
}
