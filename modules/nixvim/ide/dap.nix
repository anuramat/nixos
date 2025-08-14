{
  plugins = {
    dap.enable = true;
    #   local sign = vim.fn.sign_define
    #   sign('DapBreakpoint', { text = '', texthl = 'DapBreakpoint', linehl = '', numhl = '' })
    #   sign('DapBreakpointCondition', { text = 'C', texthl = 'DapBreakpointCondition', linehl = '', numhl = '' })
    #   sign('DapLogPoint', { text = 'L', texthl = 'DapLogPoint', linehl = '', numhl = '' })
    #   sign('DapStopped', { text = '→', texthl = 'DapStopped', linehl = '', numhl = '' })

    # { 'b', function(m) m.toggle_breakpoint() end, 'Toggle Breakpoint' },
    # { 'c', function(m) m.continue() end, 'Continue' },
    # { 'd', function(m) m.run_last() end, 'Run Last Debug Session' },
    # { 'i', function(m) m.step_into() end, 'Step Into' },
    # { 'l', log_point, 'Set Log Point' },
    # { 'n', function(m) m.step_over() end, 'Step Over' },
    # { 'o', function(m) m.step_out() end, 'Step Out' },
    # { 'r', function(m) m.repl.open() end, 'Open Debug REPL' },

    # local function log_point(m) m.set_breakpoint(nil, nil, vim.fn.input('Log point message: ')) end

    # config = function()
    #   -- some of these are used in catppuccin
    #   -- sign('DapBreakpointRejected', { text = 'R', texthl = 'DapBreakpointRejected', linehl = '', numhl = '' })
    # end,
    dap-virtual-text.enable = true;
    dap-view.enable = true;
    dap-ui.enable = true;
    #   dap-ui.settings = {
    #     #   { 'u', function(m) m.toggle() end, 'Toggle Dap UI' },
    #     #   { 'e', function(m) m.eval() end,   'Evaluate',     mode = { 'n', 'v' } },
    #     keys = {
    #       edit = "e";
    #       expand = [
    #         "<CR>"
    #         "<2-LeftMouse>"
    #       ];
    #       open = "o";
    #       remove = "d";
    #       repl = "r";
    #       toggle = "t";
    #     };
    #     floating = {
    #       border = "single";
    #       mappings = {
    #         close = [
    #           "q"
    #           "<Esc>"
    #         ];
    #       };
    #     };
    #   };
  };
}
