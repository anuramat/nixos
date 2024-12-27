-- vim: fdl=1

local u = require('utils.helpers')

local function log_point()
  require('dap').set_breakpoint(nil, nil, vim.fn.input('Log point message: '))
end

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
  keys = u.wrap_lazy_keys('<leader>d', {
    { 'c', function() require('dap').continue() end,          desc = 'Continue' },
    { 'o', function() require('dap').step_out() end,          desc = 'Step Out' },
    { 'n', function() require('dap').step_over() end,         desc = 'Step Over' },
    { 'i', function() require('dap').step_into() end,         desc = 'Step Into' },
    { 'b', function() require('dap').toggle_breakpoint() end, desc = 'Toggle Breakpoint' },
    { 'l', log_point,                                         desc = 'Set Log Point' },
    { 'r', function() require('dap').repl.open() end,         desc = 'Open Debug REPL' },
    { 'd', function() require('dap').run_last() end,          desc = 'Run Last Debug Session' },
  }, "DAP: "),
  },
  -- nvim-dap-ui
  {
    'rcarriga/nvim-dap-ui',
    dependencies = { 'mfussenegger/nvim-dap', 'nvim-neotest/nvim-nio' },
  -- stylua: ignore
  keys = u.wrap_lazy_keys('<leader>d', {
    { "u", function() require("dapui").toggle() end, desc = "Dap UI" },
    { "e", function() require("dapui").eval() end, desc = "Eval", mode = {"n", "v"} },
  }, "DAP: "),
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
